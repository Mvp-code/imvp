-- MVPx vehicle list: Tire Tread next to last odometer reported date
-- Run on UAT and PROD (fleetdb). Safe to re-run.

USE fleetdb;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'vehicle' AND COLUMN_NAME = 'TIRE_TREAD') = 0,
  'ALTER TABLE vehicle ADD COLUMN TIRE_TREAD VARCHAR(40) NULL COMMENT ''Standard tire tread'' AFTER LAST_ODOMETER_REPORTED_DATE',
  'SELECT ''TIRE_TREAD already exists'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'vehicle'
  AND COLUMN_NAME = 'TIRE_TREAD';
