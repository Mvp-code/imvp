-- fleetdb employee duplicate PREVIEW (read-only).
-- Run this first. Does not change data.
-- Duplicate key = same TRANSPORTERID (Amazon associate id).
--
-- Keep rule:
--   1) Prefer STATUS=0 (Active)
--   2) Among Active, keep the id with the most dacheckin rows
--   3) Tie-break: higher EMPLOYEEID
--   4) If no Active row, keep MAX(EMPLOYEEID) among the deleted rows
--
-- STATUS: 0=Active  1=Delete (logical)

USE fleetdb;

SELECT 'employee totals' AS section, STATUS, COUNT(*) n
FROM employee GROUP BY STATUS ORDER BY STATUS;

SELECT 'transporter ids with more than one employee row' AS section,
       COUNT(*) dup_keys
FROM (
  SELECT TRANSPORTERID
  FROM employee
  WHERE IFNULL(TRANSPORTERID,'') <> ''
  GROUP BY TRANSPORTERID
  HAVING COUNT(*) > 1
) x;

DROP TEMPORARY TABLE IF EXISTS tmp_emp_keep;
CREATE TEMPORARY TABLE tmp_emp_keep AS
SELECT e.TRANSPORTERID,
       SUBSTRING_INDEX(GROUP_CONCAT(
         e.EMPLOYEEID
         ORDER BY
           (e.STATUS = 0) DESC,
           IFNULL(c.chk, 0) DESC,
           e.EMPLOYEEID DESC
         SEPARATOR ','
       ), ',', 1) + 0 AS keep_id
FROM employee e
LEFT JOIN (
  SELECT EMPLOYEEID, COUNT(*) chk FROM dacheckin GROUP BY EMPLOYEEID
) c ON c.EMPLOYEEID = e.EMPLOYEEID
WHERE IFNULL(e.TRANSPORTERID,'') <> ''
GROUP BY e.TRANSPORTERID
HAVING COUNT(*) > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_emp_map;
CREATE TEMPORARY TABLE tmp_emp_map AS
SELECT e.EMPLOYEEID AS old_id,
       k.keep_id,
       e.TRANSPORTERID,
       e.FULLNAME,
       e.STATUS AS old_status
FROM employee e
JOIN tmp_emp_keep k ON k.TRANSPORTERID = e.TRANSPORTERID
WHERE e.EMPLOYEEID <> k.keep_id;

SELECT 'map sample (old_id -> keep_id)' AS section;
SELECT old_id, keep_id, TRANSPORTERID, FULLNAME, old_status
FROM tmp_emp_map
ORDER BY TRANSPORTERID, old_id
LIMIT 80;

SELECT 'map counts' AS section,
       COUNT(*) rows_to_retire,
       SUM(old_status = 0) live_extras_to_merge,
       SUM(old_status = 1) already_logical_delete
FROM tmp_emp_map;

SELECT 'live extra rows (both Active — these are the dangerous ones)' AS section;
SELECT m.old_id, m.keep_id, m.TRANSPORTERID, m.FULLNAME,
       (SELECT COUNT(*) FROM dacheckin d WHERE d.EMPLOYEEID = m.old_id) old_checkins,
       (SELECT COUNT(*) FROM dacheckin d WHERE d.EMPLOYEEID = m.keep_id) keep_checkins,
       (SELECT GROUP_CONCAT(USERNAME) FROM entityusers u WHERE u.EMPLOYEEID = m.old_id) old_login,
       (SELECT GROUP_CONCAT(USERNAME) FROM entityusers u WHERE u.EMPLOYEEID = m.keep_id) keep_login
FROM tmp_emp_map m
WHERE m.old_status = 0;

-- MySQL cannot reopen a TEMPORARY table in one statement (Error 1137).
-- Count each child table in its own INSERT.
DROP TEMPORARY TABLE IF EXISTS tmp_emp_remap_counts;
CREATE TEMPORARY TABLE tmp_emp_remap_counts (
  tbl VARCHAR(64) NOT NULL,
  n INT NOT NULL
);

INSERT INTO tmp_emp_remap_counts SELECT 'dacheckin', COUNT(*) FROM dacheckin d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'daconfirmation', COUNT(*) FROM daconfirmation d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employee_availability', COUNT(*) FROM employee_availability d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'entityusers', COUNT(*) FROM entityusers d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employeeforms', COUNT(*) FROM employeeforms d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employeetermination', COUNT(*) FROM employeetermination d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employeeincident', COUNT(*) FROM employeeincident d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'incidents', COUNT(*) FROM incidents d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'smstransaction', COUNT(*) FROM smstransaction d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'genericsmstrans', COUNT(*) FROM genericsmstrans d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'route_assignment', COUNT(*) FROM route_assignment d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'da_tasks', COUNT(*) FROM da_tasks d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employee_timeoff', COUNT(*) FROM employee_timeoff d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employee_extradays', COUNT(*) FROM employee_extradays d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'employee_log', COUNT(*) FROM employee_log d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'coaching_log', COUNT(*) FROM coaching_log d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'user_preferences', COUNT(*) FROM user_preferences d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'assignments', COUNT(*) FROM assignments d JOIN tmp_emp_map m ON m.old_id = d.employeeid;
INSERT INTO tmp_emp_remap_counts SELECT 'emily_calls', COUNT(*) FROM emily_calls d JOIN tmp_emp_map m ON m.old_id = d.EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'rescue_helper', COUNT(*) FROM rescue_assignment d JOIN tmp_emp_map m ON m.old_id = d.HELPER_EMPLOYEEID;
INSERT INTO tmp_emp_remap_counts SELECT 'rescue_target', COUNT(*) FROM rescue_assignment d JOIN tmp_emp_map m ON m.old_id = d.TARGET_EMPLOYEEID;

SELECT 'child rows that would be remapped' AS section, tbl, n
FROM tmp_emp_remap_counts
ORDER BY n DESC;
