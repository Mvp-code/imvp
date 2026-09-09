-- =============================================================================
-- Rollback / cleanup for a fleet inventory import batch
-- =============================================================================
-- Usage (MySQL):
--   SET @batch := 'FLEET_INV_20260812_171500';   -- paste BATCH_TAG from import output
--   SOURCE rollback_fleet_inventory.sql;
--
-- Or from CLI:
--   mysql -uroot -padmin fleetdb -e "SET @batch:='FLEET_INV_...'; SOURCE .../rollback_fleet_inventory.sql"
--
-- What it does:
--   1) Soft-deletes maintenance_log rows created by this batch (STATUS=1)
--   2) Soft-deletes vehicles INSERTED by this batch (STATUS=1)
--   3) Restores UPDATED vehicles from the backup table created by the importer
--   4) Marks the batch as rolled back in fleet_import_batch.NOTES
-- =============================================================================

SET @batch := IFNULL(@batch, '');

SELECT IF(@batch = '', 'ERROR: SET @batch := ''FLEET_INV_YYYYMMDD_HHMMSS'' first', @batch) AS batch_tag;

-- Resolve backup table names (importer uses bkup_vehicle_<safe_batch>)
SET @safe := LOWER(REPLACE(REPLACE(@batch, '-', '_'), ' ', '_'));
SET @veh_bk := CONCAT('bkup_vehicle_', @safe);
SET @log_bk := CONCAT('bkup_maint_log_', @safe);

-- Preview
SELECT 'maint_logs_to_remove' AS what, COUNT(*) AS cnt
FROM vehicle_maintenance_log WHERE CREATE_USER = @batch AND STATUS = 0
UNION ALL
SELECT 'vehicles_inserted_by_batch', COUNT(*)
FROM vehicle WHERE CREATE_USER = @batch AND STATUS IN (0,4)
UNION ALL
SELECT 'vehicles_updated_by_batch', COUNT(*)
FROM fleet_import_touch WHERE BATCH_TAG = @batch AND ACTION = 'UPDATE';

-- 1) Soft-delete imported maintenance history
UPDATE vehicle_maintenance_log
SET STATUS = 1,
    UPDATE_USER = CONCAT('ROLLBACK_', @batch),
    UPDATE_DATE = NOW()
WHERE CREATE_USER = @batch
  AND STATUS = 0;

-- 2) Soft-delete vehicles that were newly inserted by this batch
UPDATE vehicle
SET STATUS = 1,
    UPDATE_USER = CONCAT('ROLLBACK_', @batch),
    UPDATE_DATE = NOW()
WHERE CREATE_USER = @batch
  AND STATUS IN (0, 4);

-- 3) Restore updated vehicles from backup (dynamic SQL)
--    Only restores rows that were UPDATED by this batch and still exist.
SET @sql := CONCAT(
  'UPDATE vehicle v ',
  'JOIN `', @veh_bk, '` b ON b.VEHICLEID = v.VEHICLEID ',
  'JOIN fleet_import_touch t ON t.VEHICLEID = v.VEHICLEID AND t.BATCH_TAG = ''', @batch, ''' AND t.ACTION = ''UPDATE'' ',
  'SET ',
  ' v.VEHICLENUMBER = b.VEHICLENUMBER,',
  ' v.LICENSEPLATE = b.LICENSEPLATE,',
  ' v.VEHICLETYPE = b.VEHICLETYPE,',
  ' v.OWNERSHIPTYPE = b.OWNERSHIPTYPE,',
  ' v.PROVIDER = b.PROVIDER,',
  ' v.SERVICETIER = b.SERVICETIER,',
  ' v.VEHICLEYEAR = b.VEHICLEYEAR,',
  ' v.OPERATIONALSTATUS = b.OPERATIONALSTATUS,',
  ' v.STATUS = b.STATUS,',
  ' v.STATUSREASONCODE = b.STATUSREASONCODE,',
  ' v.STATUSREASONMSG = b.STATUSREASONMSG,',
  ' v.REGISTRATIONEXPIRY = b.REGISTRATIONEXPIRY,',
  ' v.STATION = b.STATION,',
  ' v.OUT_FOR_REPAIR = b.OUT_FOR_REPAIR,',
  ' v.UPDATE_USER = CONCAT(''ROLLBACK_'', ''', @batch, '''),',
  ' v.UPDATE_DATE = NOW()'
);

SELECT @sql AS restore_sql;
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE fleet_import_batch
SET NOTES = CONCAT(IFNULL(NOTES,''), ' | ROLLED_BACK=', NOW())
WHERE BATCH_TAG = @batch;

SELECT 'rollback_complete' AS result, @batch AS batch_tag;
