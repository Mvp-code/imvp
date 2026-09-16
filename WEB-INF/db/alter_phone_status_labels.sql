-- Phone status labels + extra options for "add new".
-- Maps 0 -> Active, 4 -> Suspended. Current status 0-3 -> names.
-- Safe to re-run.

USE fleetdb;

CREATE TABLE IF NOT EXISTS phone_status_option (
  PHONE_STATUS_OPTIONID INT(11) NOT NULL AUTO_INCREMENT,
  ENTITYID INT(11) NOT NULL DEFAULT 1,
  KIND VARCHAR(20) NOT NULL,
  STATUS_NAME VARCHAR(80) NOT NULL,
  CREATE_USER VARCHAR(100) DEFAULT NULL,
  CREATE_DATE DATETIME DEFAULT NULL,
  STATUS INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (PHONE_STATUS_OPTIONID),
  UNIQUE KEY UK_PHONE_STATUS_OPT (ENTITYID, KIND, STATUS_NAME)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO phone_status_option (ENTITYID, KIND, STATUS_NAME, CREATE_USER, CREATE_DATE, STATUS)
VALUES
  (1, 'phone', 'Active', 'seed', NOW(), 0),
  (1, 'phone', 'Suspended', 'seed', NOW(), 0),
  (1, 'current', 'In Use', 'seed', NOW(), 0),
  (1, 'current', 'Not Used', 'seed', NOW(), 0),
  (1, 'current', 'Damaged', 'seed', NOW(), 0),
  (1, 'current', 'Lost', 'seed', NOW(), 0);

ALTER TABLE phones MODIFY COLUMN PHONESTATUS VARCHAR(80) DEFAULT 'Active';
ALTER TABLE phones MODIFY COLUMN CURRENTSTATUS VARCHAR(80) DEFAULT 'In Use';

UPDATE phones
SET PHONESTATUS = CASE
  WHEN PHONESTATUS IS NULL OR PHONESTATUS IN ('', '0', 'Active') THEN 'Active'
  WHEN PHONESTATUS IN ('4', 'Inactive', 'Suspended') THEN 'Suspended'
  ELSE PHONESTATUS
END
WHERE STATUS != 1;

UPDATE phones
SET CURRENTSTATUS = CASE
  WHEN CURRENTSTATUS IS NULL OR CURRENTSTATUS IN ('', '0', 'In Use') THEN 'In Use'
  WHEN CURRENTSTATUS IN ('1', 'Not Used') THEN 'Not Used'
  WHEN CURRENTSTATUS IN ('2', 'Damaged') THEN 'Damaged'
  WHEN CURRENTSTATUS IN ('3', 'Lost') THEN 'Lost'
  ELSE CURRENTSTATUS
END
WHERE STATUS != 1;
