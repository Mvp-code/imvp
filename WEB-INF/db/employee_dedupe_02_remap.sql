-- fleetdb employee duplicate REMAP + cleanup.
-- Run employee_dedupe_01_preview.sql first and read the map.
--
-- Default ENDS IN ROLLBACK. When you are ready to keep the change,
-- comment the ROLLBACK line and uncomment COMMIT.
--
-- Take a dump first:
--   mysqldump -uroot -p fleetdb employee dacheckin daconfirmation entityusers
--     employee_availability employee_schedule > emp_dedupe_backup.sql
--
-- Keep rule matches the preview script (Active + most check-ins + higher id).

USE fleetdb;

START TRANSACTION;

DROP TABLE IF EXISTS emp_dedupe_map;
CREATE TABLE emp_dedupe_map (
  old_id INT NOT NULL PRIMARY KEY,
  keep_id INT NOT NULL,
  transporterid VARCHAR(30) NULL,
  fullname VARCHAR(150) NULL,
  old_status INT NULL,
  KEY idx_keep (keep_id)
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS tmp_emp_keep;
CREATE TEMPORARY TABLE tmp_emp_keep AS
SELECT e.TRANSPORTERID,
       SUBSTRING_INDEX(GROUP_CONCAT(
         e.EMPLOYEEID
         ORDER BY (e.STATUS = 0) DESC, IFNULL(c.chk, 0) DESC, e.EMPLOYEEID DESC
         SEPARATOR ','
       ), ',', 1) + 0 AS keep_id
FROM employee e
LEFT JOIN (
  SELECT EMPLOYEEID, COUNT(*) chk FROM dacheckin GROUP BY EMPLOYEEID
) c ON c.EMPLOYEEID = e.EMPLOYEEID
WHERE IFNULL(e.TRANSPORTERID,'') <> ''
GROUP BY e.TRANSPORTERID
HAVING COUNT(*) > 1;

INSERT INTO emp_dedupe_map (old_id, keep_id, transporterid, fullname, old_status)
SELECT e.EMPLOYEEID, k.keep_id, e.TRANSPORTERID, e.FULLNAME, e.STATUS
FROM employee e
JOIN tmp_emp_keep k ON k.TRANSPORTERID = e.TRANSPORTERID
WHERE e.EMPLOYEEID <> k.keep_id;

SELECT 'emp_dedupe_map rows' AS step, COUNT(*) n FROM emp_dedupe_map;

-- ---------- child remaps (history keeps the same rows, new employee id) ----------
UPDATE dacheckin d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE daconfirmation d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE incidents d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE smstransaction d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE genericsmstrans d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE route_assignment d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE da_tasks d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employeeforms d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employeetermination d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employeeincident d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employee_timeoff d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employee_extradays d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE employee_log d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE coaching_log d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE emily_calls d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

UPDATE rescue_assignment d JOIN emp_dedupe_map m ON m.old_id = d.HELPER_EMPLOYEEID
SET d.HELPER_EMPLOYEEID = m.keep_id;

UPDATE rescue_assignment d JOIN emp_dedupe_map m ON m.old_id = d.TARGET_EMPLOYEEID
SET d.TARGET_EMPLOYEEID = m.keep_id;

-- assignments: unique (work_date, employeeid) — drop extra if keep already has that day
DELETE a FROM assignments a
JOIN emp_dedupe_map m ON m.old_id = a.employeeid
JOIN assignments k ON k.work_date = a.work_date AND k.employeeid = m.keep_id;

UPDATE assignments a JOIN emp_dedupe_map m ON m.old_id = a.employeeid
SET a.employeeid = m.keep_id;

-- user_preferences: unique (USERID, ENTITYID) not employeeid; remap is safe
UPDATE user_preferences d JOIN emp_dedupe_map m ON m.old_id = d.EMPLOYEEID
SET d.EMPLOYEEID = m.keep_id;

-- entityusers: keep already has the login. Drop extra user rows on old_id
-- (same USERNAME was seen on live twins, e.g. Brandon / Ramar).
DELETE u FROM entityusers u
JOIN emp_dedupe_map m ON m.old_id = u.EMPLOYEEID
JOIN entityusers k ON k.EMPLOYEEID = m.keep_id;

UPDATE entityusers u JOIN emp_dedupe_map m ON m.old_id = u.EMPLOYEEID
SET u.EMPLOYEEID = m.keep_id;

-- availability + schedule: point schedule at keep's availability, then drop extra avail rows
DROP TEMPORARY TABLE IF EXISTS tmp_avail_keep;
CREATE TEMPORARY TABLE tmp_avail_keep AS
SELECT m.old_id,
       (SELECT MIN(ka.EMPLOYEE_AVAILABILITYID)
        FROM employee_availability ka
        WHERE ka.EMPLOYEEID = m.keep_id) AS keep_avail_id
FROM emp_dedupe_map m;

UPDATE employee_schedule s
JOIN employee_availability av ON av.EMPLOYEE_AVAILABILITYID = s.EMPLOYEE_AVAILABILITYID
JOIN tmp_avail_keep t ON t.old_id = av.EMPLOYEEID
SET s.EMPLOYEE_AVAILABILITYID = t.keep_avail_id
WHERE t.keep_avail_id IS NOT NULL
  AND s.EMPLOYEE_AVAILABILITYID <> t.keep_avail_id;

-- leftover avail rows on old_id: if keep has no avail, steal one row; else delete
UPDATE employee_availability av
JOIN emp_dedupe_map m ON m.old_id = av.EMPLOYEEID
LEFT JOIN employee_availability ka ON ka.EMPLOYEEID = m.keep_id
SET av.EMPLOYEEID = m.keep_id
WHERE ka.EMPLOYEE_AVAILABILITYID IS NULL;

DELETE av FROM employee_availability av
JOIN emp_dedupe_map m ON m.old_id = av.EMPLOYEEID;

-- ---------- retire duplicate employee rows ----------
DELETE e FROM employee e
JOIN emp_dedupe_map m ON m.old_id = e.EMPLOYEEID;

SELECT 'remaining dup transporter ids (should be 0)' AS step, COUNT(*) n
FROM (
  SELECT TRANSPORTERID FROM employee
  WHERE IFNULL(TRANSPORTERID,'') <> ''
  GROUP BY TRANSPORTERID HAVING COUNT(*) > 1
) x;

SELECT 'employee counts after' AS step, STATUS, COUNT(*) n
FROM employee GROUP BY STATUS ORDER BY STATUS;

-- STOP HERE until you have reviewed the counts above.
ROLLBACK;
-- COMMIT;
