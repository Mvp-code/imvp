-- After remap, two Active confirmation rows can share one EMPLOYEEID + day.
-- Keep the strongest confirmation; logical-delete the extras (STATUS=1).
--
-- Default ENDS IN ROLLBACK. Switch to COMMIT after the counts look right.

USE fleetdb;

START TRANSACTION;

DROP TABLE IF EXISTS emp_confirm_keep;
CREATE TABLE emp_confirm_keep (
  keep_id INT NOT NULL PRIMARY KEY,
  employeeid INT NOT NULL,
  conf_day DATE NOT NULL,
  KEY idx_emp_day (employeeid, conf_day)
) ENGINE=InnoDB;

INSERT INTO emp_confirm_keep (keep_id, employeeid, conf_day)
SELECT keep_id, employeeid, conf_day
FROM (
  SELECT C.DACONFIRMATIONID AS keep_id,
         C.EMPLOYEEID AS employeeid,
         DATE(C.SCHEDULEDATE) AS conf_day,
         ROW_NUMBER() OVER (
           PARTITION BY C.EMPLOYEEID, DATE(C.SCHEDULEDATE)
           ORDER BY
             CASE C.CONFIRMATION
               WHEN 'Confirmed' THEN 3
               WHEN 'Confirmed - No block' THEN 2
               WHEN 'Review' THEN 1
               ELSE 0
             END DESC,
             C.DACONFIRMATIONID DESC
         ) AS rn
  FROM daconfirmation C
  WHERE C.STATUS = 0
) ranked
WHERE rn = 1
  AND EXISTS (
    SELECT 1 FROM daconfirmation D
    WHERE D.STATUS = 0
      AND D.EMPLOYEEID = ranked.employeeid
      AND DATE(D.SCHEDULEDATE) = ranked.conf_day
      AND D.DACONFIRMATIONID <> ranked.keep_id
  );

SELECT 'dup person-day groups to close' AS step, COUNT(*) n FROM emp_confirm_keep;

SELECT 'extra confirmation rows to logical-delete' AS step, COUNT(*) n
FROM daconfirmation C
JOIN emp_confirm_keep K
  ON K.employeeid = C.EMPLOYEEID
 AND DATE(C.SCHEDULEDATE) = K.conf_day
WHERE C.STATUS = 0
  AND C.DACONFIRMATIONID <> K.keep_id;

UPDATE daconfirmation C
JOIN emp_confirm_keep K
  ON K.employeeid = C.EMPLOYEEID
 AND DATE(C.SCHEDULEDATE) = K.conf_day
SET C.STATUS = 1,
    C.UPDATE_USER = 'dedupe04',
    C.UPDATE_DATE = NOW()
WHERE C.STATUS = 0
  AND C.DACONFIRMATIONID <> K.keep_id;

SELECT 'remaining dup person-day confirmations (should be 0)' AS step, COUNT(*) n
FROM (
  SELECT EMPLOYEEID, DATE(SCHEDULEDATE) d
  FROM daconfirmation
  WHERE STATUS = 0
  GROUP BY EMPLOYEEID, DATE(SCHEDULEDATE)
  HAVING COUNT(*) > 1
) x;

-- STOP HERE until you have reviewed the counts above.
ROLLBACK;
-- COMMIT;
