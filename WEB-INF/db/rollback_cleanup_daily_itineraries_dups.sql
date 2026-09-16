-- Restore itinerary rows inactivated by cleanup_daily_itineraries_dups.sql.

USE fleetdb;

SELECT COUNT(*) AS tagged_deleted
FROM DAILY_ITINERARIES
WHERE STATUS = 1
  AND UPDATE_USER = 'itin-dup-cleanup';

SET SQL_SAFE_UPDATES = 0;

UPDATE DAILY_ITINERARIES
SET STATUS = 0
WHERE STATUS = 1
  AND UPDATE_USER = 'itin-dup-cleanup'
  AND DAILY_ITINERARIESID IN (
    SELECT id FROM (
      SELECT DAILY_ITINERARIESID AS id
      FROM DAILY_ITINERARIES
      WHERE STATUS = 1
        AND UPDATE_USER = 'itin-dup-cleanup'
    ) t
  );

SET SQL_SAFE_UPDATES = 1;
