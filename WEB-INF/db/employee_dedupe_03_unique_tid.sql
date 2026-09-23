-- Unique Amazon transporter id per entity.
-- Run AFTER employee_dedupe_02_remap.sql has been COMMITTED.
-- Empty transporter values are stored as NULL so they do not collide.

USE fleetdb;

UPDATE employee
SET TRANSPORTERID = NULL
WHERE TRIM(IFNULL(TRANSPORTERID,'')) = '';

-- Must be 0 before the index can be created.
SELECT 'dup transporter ids remaining (must be 0)' AS step, COUNT(*) n
FROM (
  SELECT ENTITYID, UPPER(TRIM(TRANSPORTERID)) tid
  FROM employee
  WHERE TRANSPORTERID IS NOT NULL
  GROUP BY ENTITYID, UPPER(TRIM(TRANSPORTERID))
  HAVING COUNT(*) > 1
) x;

CREATE UNIQUE INDEX uk_employee_entity_transporter
  ON employee (ENTITYID, TRANSPORTERID);
