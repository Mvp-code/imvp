-- ============================================================
--  ROLLBACK for deactivate_duplicate_logins.sql
--
--  RecordStatus: 0 = ACTIVE, 1 = DELETE
--  Cleanup tagged rows with UPDATE_USER = 'dup-cleanup'
--
--  Case 1 — PART B is still in an open transaction (not COMMIT):
--      ROLLBACK;
--      DROP TABLE IF EXISTS tmp_dup_login_keep;
--    Stop. Do not run PART B below.
--
--  Case 2 — you already COMMITTED. Run PART A then PART B.
--    Restores STATUS=0 on rows this cleanup inactivated.
--    Employees also get REVIEW_STATUS=0.
-- ============================================================

USE fleetdb;

-- ------------------------------------------------------------
-- Case 1 — uncommitted PART B
-- ------------------------------------------------------------
-- ROLLBACK;
-- DROP TABLE IF EXISTS tmp_dup_login_keep;

-- ------------------------------------------------------------
-- PART A — PREVIEW (committed cleanup only)
-- ------------------------------------------------------------

SELECT 'ENTITYUSERS' AS tbl, COUNT(*) AS n
FROM ENTITYUSERS WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'EMPLOYEE', COUNT(*)
FROM EMPLOYEE WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'CONTACT', COUNT(*)
FROM CONTACT WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'ADDRESS', COUNT(*)
FROM ADDRESS WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup';

SELECT ENTITYUSERSID, USERNAME, EMPLOYEEID, STATUS, UPDATE_DATE
FROM ENTITYUSERS
WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
ORDER BY USERNAME, ENTITYUSERSID;

SELECT EMPLOYEEID, FULLNAME, STATUS, REVIEW_STATUS, CONTACTID, ADDRESSID, UPDATE_DATE
FROM EMPLOYEE
WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
ORDER BY EMPLOYEEID;

SELECT CONTACTID, MOBILE, EMAIL, STATUS, UPDATE_DATE
FROM CONTACT
WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
ORDER BY MOBILE, CONTACTID;

SELECT ADDRESSID, STREET1, CITY, STATE, ZIP, STATUS, UPDATE_DATE
FROM ADDRESS
WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
ORDER BY ADDRESSID;

-- ------------------------------------------------------------
-- PART B — APPLY restore. Workbench-safe (PK + SQL_SAFE_UPDATES).
-- ------------------------------------------------------------

SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

UPDATE ENTITYUSERS
SET STATUS = 0,
    UPDATE_USER = 'dup-rollback',
    UPDATE_DATE = NOW()
WHERE ENTITYUSERSID IN (
  SELECT ENTITYUSERSID FROM (
    SELECT ENTITYUSERSID
    FROM ENTITYUSERS
    WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
  ) z
);

UPDATE EMPLOYEE
SET STATUS = 0,
    REVIEW_STATUS = 0,
    UPDATE_USER = 'dup-rollback',
    UPDATE_DATE = NOW()
WHERE EMPLOYEEID IN (
  SELECT EMPLOYEEID FROM (
    SELECT EMPLOYEEID
    FROM EMPLOYEE
    WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
  ) z
);

UPDATE CONTACT
SET STATUS = 0,
    UPDATE_USER = 'dup-rollback',
    UPDATE_DATE = NOW()
WHERE CONTACTID IN (
  SELECT CONTACTID FROM (
    SELECT CONTACTID
    FROM CONTACT
    WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
  ) z
);

UPDATE ADDRESS
SET STATUS = 0,
    UPDATE_USER = 'dup-rollback',
    UPDATE_DATE = NOW()
WHERE ADDRESSID IN (
  SELECT ADDRESSID FROM (
    SELECT ADDRESSID
    FROM ADDRESS
    WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
  ) z
);

SET SQL_SAFE_UPDATES = 1;

-- Remaining cleanup tags should be 0
SELECT 'ENTITYUSERS still tagged' AS what, COUNT(*) AS n
FROM ENTITYUSERS WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'EMPLOYEE still tagged', COUNT(*)
FROM EMPLOYEE WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'CONTACT still tagged', COUNT(*)
FROM CONTACT WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup'
UNION ALL
SELECT 'ADDRESS still tagged', COUNT(*)
FROM ADDRESS WHERE STATUS = 1 AND UPDATE_USER = 'dup-cleanup';

SELECT 'active duplicate usernames' AS what, COUNT(*) AS n
FROM (
  SELECT USERNAME
  FROM ENTITYUSERS
  WHERE STATUS = 0
  GROUP BY USERNAME
  HAVING COUNT(*) > 1
) t;

-- If verify looks right:
--   COMMIT;
-- If not:
--   ROLLBACK;
