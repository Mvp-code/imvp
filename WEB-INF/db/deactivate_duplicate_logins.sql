-- ============================================================
--  Deactivate duplicate logins + leftover employee/contact/address
--
--  RecordStatus: 0 = ACTIVE, 1 = DELETE (soft delete — no DELETE FROM)
--
--  Cause: the same mobile was inserted again as USERNAME, so
--  ENTITYUSERS had 2+ active rows. Login required exactly one row
--  and failed with "Invalid credentials". Related EMPLOYEE /
--  CONTACT / ADDRESS copies were left behind.
--
--  Keep rule (per USERNAME among STATUS=0 rows):
--    1. Prefer the row whose EMPLOYEE is still active
--       (EMPLOYEE.STATUS=0 AND REVIEW_STATUS=0)
--    2. Tie-break: lowest ENTITYUSERSID (oldest account)
--    Keep that employee's CONTACT + ADDRESS.
--    Soft-delete every other login, employee, unused contact,
--    and unused address in the cluster.
--
--  How to run (MySQL 8 / Workbench, database fleetdb):
--    1. Run PART A (preview). Review the keep vs drop lists.
--    2. Run PART B (apply) in the same session.
--    3. If the verify counts look right: COMMIT;
--       If not: ROLLBACK;
-- ============================================================

USE fleetdb;

-- ------------------------------------------------------------
-- PART A — PREVIEW
-- ------------------------------------------------------------

DROP TABLE IF EXISTS tmp_dup_login_keep;
CREATE TABLE tmp_dup_login_keep (
  USERNAME        VARCHAR(50) NOT NULL PRIMARY KEY,
  KEEP_USERID     INT NOT NULL,
  KEEP_EMPID      INT NULL,
  KEEP_CONTACTID  INT NULL,
  KEEP_ADDRESSID  INT NULL
) ENGINE=Memory;

INSERT INTO tmp_dup_login_keep (USERNAME, KEEP_USERID, KEEP_EMPID, KEEP_CONTACTID, KEEP_ADDRESSID)
SELECT USERNAME, ENTITYUSERSID, EMPLOYEEID, CONTACTID, ADDRESSID
FROM (
  SELECT u.USERNAME,
         u.ENTITYUSERSID,
         u.EMPLOYEEID,
         e.CONTACTID,
         e.ADDRESSID,
         ROW_NUMBER() OVER (
           PARTITION BY u.USERNAME
           ORDER BY
             CASE
               WHEN e.EMPLOYEEID IS NOT NULL
                AND e.STATUS = 0
                AND e.REVIEW_STATUS = 0 THEN 0
               ELSE 1
             END,
             u.ENTITYUSERSID
         ) AS rn
  FROM ENTITYUSERS u
  LEFT JOIN EMPLOYEE e ON e.EMPLOYEEID = u.EMPLOYEEID
  WHERE u.STATUS = 0
    AND u.USERNAME IN (
      SELECT USERNAME
      FROM ENTITYUSERS
      WHERE STATUS = 0
      GROUP BY USERNAME
      HAVING COUNT(*) > 1
    )
) ranked
WHERE rn = 1;

SELECT 'dup usernames' AS what, COUNT(*) AS n FROM tmp_dup_login_keep
UNION ALL
SELECT 'extra ENTITYUSERS to inactivate', COUNT(*)
FROM ENTITYUSERS u
JOIN tmp_dup_login_keep k ON k.USERNAME = u.USERNAME
WHERE u.STATUS = 0 AND u.ENTITYUSERSID <> k.KEEP_USERID
UNION ALL
SELECT 'extra EMPLOYEE to inactivate', COUNT(*)
FROM EMPLOYEE e
JOIN CONTACT c ON c.CONTACTID = e.CONTACTID
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
WHERE e.STATUS = 0
  AND (k.KEEP_EMPID IS NULL OR e.EMPLOYEEID <> k.KEEP_EMPID)
UNION ALL
SELECT 'extra CONTACT to inactivate', COUNT(*)
FROM CONTACT c
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
WHERE c.STATUS = 0
  AND (k.KEEP_CONTACTID IS NULL OR c.CONTACTID <> k.KEEP_CONTACTID);

-- Who we KEEP
SELECT k.USERNAME, k.KEEP_USERID, k.KEEP_EMPID, e.FULLNAME, k.KEEP_CONTACTID, k.KEEP_ADDRESSID
FROM tmp_dup_login_keep k
LEFT JOIN EMPLOYEE e ON e.EMPLOYEEID = k.KEEP_EMPID
ORDER BY k.USERNAME;

-- ENTITYUSERS that will go STATUS=1
SELECT u.ENTITYUSERSID, u.USERNAME, u.EMPLOYEEID, u.STATUS, u.CREATE_DATE, u.CREATE_USER
FROM ENTITYUSERS u
JOIN tmp_dup_login_keep k ON k.USERNAME = u.USERNAME
WHERE u.STATUS = 0 AND u.ENTITYUSERSID <> k.KEEP_USERID
ORDER BY u.USERNAME, u.ENTITYUSERSID;

-- EMPLOYEE that will go STATUS=1 (same mobile as the login username)
SELECT e.EMPLOYEEID, e.FULLNAME, e.STATUS, e.REVIEW_STATUS, e.CONTACTID, e.ADDRESSID, c.MOBILE
FROM EMPLOYEE e
JOIN CONTACT c ON c.CONTACTID = e.CONTACTID
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
WHERE e.STATUS = 0
  AND (k.KEEP_EMPID IS NULL OR e.EMPLOYEEID <> k.KEEP_EMPID)
ORDER BY c.MOBILE, e.EMPLOYEEID;

-- CONTACT that will go STATUS=1
SELECT c.CONTACTID, c.MOBILE, c.EMAIL, c.STATUS, c.CREATE_DATE
FROM CONTACT c
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
WHERE c.STATUS = 0
  AND (k.KEEP_CONTACTID IS NULL OR c.CONTACTID <> k.KEEP_CONTACTID)
ORDER BY c.MOBILE, c.CONTACTID;

-- ADDRESS that will go STATUS=1 (only if no remaining active employee uses it)
SELECT a.ADDRESSID, a.STREET1, a.CITY, a.STATE, a.ZIP, a.STATUS
FROM ADDRESS a
WHERE a.STATUS = 0
  AND a.ADDRESSID IN (
    SELECT e.ADDRESSID
    FROM EMPLOYEE e
    JOIN CONTACT c ON c.CONTACTID = e.CONTACTID
    JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
    WHERE e.ADDRESSID IS NOT NULL
      AND (k.KEEP_EMPID IS NULL OR e.EMPLOYEEID <> k.KEEP_EMPID)
  )
  AND a.ADDRESSID NOT IN (
    SELECT e2.ADDRESSID FROM EMPLOYEE e2
    WHERE e2.STATUS = 0 AND e2.ADDRESSID IS NOT NULL
      AND e2.EMPLOYEEID IN (SELECT KEEP_EMPID FROM tmp_dup_login_keep WHERE KEEP_EMPID IS NOT NULL)
  );

-- ------------------------------------------------------------
-- PART B — APPLY (soft delete). Run after you accept PART A.
-- ------------------------------------------------------------

START TRANSACTION;

-- 1) Extra logins
UPDATE ENTITYUSERS u
JOIN tmp_dup_login_keep k ON k.USERNAME = u.USERNAME
SET u.STATUS = 1,
    u.UPDATE_USER = 'dup-cleanup',
    u.UPDATE_DATE = NOW()
WHERE u.STATUS = 0
  AND u.ENTITYUSERSID <> k.KEEP_USERID;

-- 2) Extra employees (same mobile as the login username)
UPDATE EMPLOYEE e
JOIN CONTACT c ON c.CONTACTID = e.CONTACTID
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
SET e.STATUS = 1,
    e.REVIEW_STATUS = 1,
    e.UPDATE_USER = 'dup-cleanup',
    e.UPDATE_DATE = NOW()
WHERE e.STATUS = 0
  AND (k.KEEP_EMPID IS NULL OR e.EMPLOYEEID <> k.KEEP_EMPID);

-- 3) Extra contacts with that mobile (including contacts with no employee)
UPDATE CONTACT c
JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
SET c.STATUS = 1,
    c.UPDATE_USER = 'dup-cleanup',
    c.UPDATE_DATE = NOW()
WHERE c.STATUS = 0
  AND (k.KEEP_CONTACTID IS NULL OR c.CONTACTID <> k.KEEP_CONTACTID);

-- 4) Addresses only used by the extra employees
UPDATE ADDRESS a
SET a.STATUS = 1,
    a.UPDATE_USER = 'dup-cleanup',
    a.UPDATE_DATE = NOW()
WHERE a.STATUS = 0
  AND a.ADDRESSID IN (
    SELECT x.ADDRESSID FROM (
      SELECT e.ADDRESSID
      FROM EMPLOYEE e
      JOIN CONTACT c ON c.CONTACTID = e.CONTACTID
      JOIN tmp_dup_login_keep k ON k.USERNAME = c.MOBILE
      WHERE e.ADDRESSID IS NOT NULL
        AND (k.KEEP_EMPID IS NULL OR e.EMPLOYEEID <> k.KEEP_EMPID)
    ) x
  )
  AND a.ADDRESSID NOT IN (
    SELECT y.ADDRESSID FROM (
      SELECT e2.ADDRESSID
      FROM EMPLOYEE e2
      WHERE e2.STATUS = 0
        AND e2.ADDRESSID IS NOT NULL
        AND e2.EMPLOYEEID IN (SELECT KEEP_EMPID FROM tmp_dup_login_keep WHERE KEEP_EMPID IS NOT NULL)
    ) y
  );

-- Verify: every kept username should now have exactly one active login.
-- This result set should be EMPTY.
SELECT u.USERNAME, COUNT(*) AS active_logins
FROM ENTITYUSERS u
JOIN tmp_dup_login_keep k ON k.USERNAME = u.USERNAME
WHERE u.STATUS = 0
GROUP BY u.USERNAME
HAVING COUNT(*) <> 1;

SELECT 'active duplicate usernames left' AS what, COUNT(*) AS n
FROM (
  SELECT USERNAME
  FROM ENTITYUSERS
  WHERE STATUS = 0
  GROUP BY USERNAME
  HAVING COUNT(*) > 1
) t;

-- If verify looks right, run these two lines:
--   COMMIT;
--   DROP TABLE IF EXISTS tmp_dup_login_keep;
-- If not:
--   ROLLBACK;
--   DROP TABLE IF EXISTS tmp_dup_login_keep;
--
-- Do not DROP before COMMIT — DROP TABLE commits implicitly in MySQL.
