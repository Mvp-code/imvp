-- ============================================================
--  New Amazon-report upload tables (dedicated loaders, NO drop).
--  Reload = create-once + delete-by-key + insert. STATUS: 0=ACTIVE,1=DELETE.
--  Run against fleetdb. AUTO_INCREMENT PK matches the existing DAO pattern
--  (db.getAutoIncrementArray).
-- ============================================================
USE fleetdb;

-- 1) SENTIMENT  (loader implemented: insSentiment)
--    Reload rule: update existing + insert new.
--    Key: ENTITYID, SENTIMENT_WEEK, SENTIMENT_MONTH, STATION, QUESTION
CREATE TABLE IF NOT EXISTS SENTIMENT (
  SENTIMENTID         INT(11)      NOT NULL AUTO_INCREMENT,
  ENTITYID            INT(11)      NOT NULL DEFAULT 1,
  SENTIMENT_WEEK      VARCHAR(10),
  SENTIMENT_MONTH     VARCHAR(10),
  COUNTRY             VARCHAR(10),
  STATION             VARCHAR(20),
  DSP                 VARCHAR(50),
  QUESTION            VARCHAR(500),
  RESPONSE_RATE       VARCHAR(20),
  FAVORABLE_RATE      VARCHAR(20),
  T6M_FAVORABLE_RATE  VARCHAR(20),
  CREATE_USER         VARCHAR(100),
  CREATE_DATE         DATETIME,
  STATUS              INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (SENTIMENTID),
  KEY IDX_SENTIMENT (ENTITYID, SENTIMENT_WEEK, SENTIMENT_MONTH, STATION)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2) WORKFORCE_DA  (loader: pending)  Reload: replace snapshot (delete all for station, reload)
--    Key: ENTITYID, TRANSPORTERID, STATION
CREATE TABLE IF NOT EXISTS WORKFORCE_DA (
  WORKFORCE_DAID              INT(11)      NOT NULL AUTO_INCREMENT,
  ENTITYID                   INT(11)      NOT NULL DEFAULT 1,
  DSP                        VARCHAR(50),
  STATION                    VARCHAR(20),
  WF_YEAR                    VARCHAR(10),
  WF_WEEK                    VARCHAR(10),
  EMPLOYEEID                 VARCHAR(30),
  TRANSPORTERID              VARCHAR(30),
  NAME                       VARCHAR(120),
  DAYS_SINCE_LAST_DELIVERED  VARCHAR(20),
  DELIVERY_STATUS            VARCHAR(40),
  DRIVER_STATUS              VARCHAR(40),
  DRIVER_STATUS_REASON_CODE  VARCHAR(60),
  LIFETIME_ROUTES            VARCHAR(20),
  ROUTES_IN_WEEK             VARCHAR(20),
  TENURE_STATUS              VARCHAR(30),
  COUNTRY                    VARCHAR(10),
  CREATE_USER                VARCHAR(100),
  CREATE_DATE                DATETIME,
  STATUS                     INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (WORKFORCE_DAID),
  KEY IDX_WFDA (ENTITYID, STATION, TRANSPORTERID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3) WORKFORCE_SUMMARY  (loader: pending)  Reload: delete same week & reload
--    Key: ENTITYID, WF_YEAR, WF_WEEK
CREATE TABLE IF NOT EXISTS WORKFORCE_SUMMARY (
  WORKFORCE_SUMMARYID       INT(11)      NOT NULL AUTO_INCREMENT,
  ENTITYID                  INT(11)      NOT NULL DEFAULT 1,
  COUNTRY                   VARCHAR(10),
  DSP                       VARCHAR(50),
  STATION                   VARCHAR(20),
  WF_YEAR                   VARCHAR(10),
  WF_WEEK                   VARCHAR(10),
  DELIVERING_DAS_TENURED    VARCHAR(20),
  DELIVERING_DAS_TOTAL      VARCHAR(20),
  TENURED_WORKFORCE_RAW     VARCHAR(40),
  EXEMPTIONS                VARCHAR(500),
  TENURED_WORKFORCE_FINAL   VARCHAR(40),
  DSP_TENURE                VARCHAR(40),
  DSP_TENURE_STATUS         VARCHAR(40),
  TENURED_WORKFORCE_TIER    VARCHAR(40),
  CREATE_USER               VARCHAR(100),
  CREATE_DATE               DATETIME,
  STATUS                    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (WORKFORCE_SUMMARYID),
  KEY IDX_WFSUM (ENTITYID, WF_YEAR, WF_WEEK)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) DA_DAILY_SUMMARY  (loader: pending)  Reload: delete if exists & reload
--    Key: ENTITYID, ROUTE_CODE, ITINERARY_DATE
CREATE TABLE IF NOT EXISTS DA_DAILY_SUMMARY (
  DA_DAILY_SUMMARYID   INT(11)      NOT NULL AUTO_INCREMENT,
  ENTITYID             INT(11)      NOT NULL DEFAULT 1,
  ROUTE_CODE           VARCHAR(80),
  ALL_STOPS            VARCHAR(20),
  TOTAL_PACKAGES       VARCHAR(20),
  AVG_PACE_STOPS_HR    VARCHAR(20),
  TOTAL_BREAK_TIME     VARCHAR(20),
  ITINERARY_DATE       VARCHAR(20),
  DRIVER_NAME          VARCHAR(120),
  TRANSPORTER          VARCHAR(30),
  SIGNIN_TIME          VARCHAR(20),
  SIGNOUT_TIME         VARCHAR(20),
  LAST_STOP_TIME       VARCHAR(20),
  TIME_ON_ROAD         VARCHAR(20),
  STATION              VARCHAR(20),
  CREATE_USER          VARCHAR(100),
  CREATE_DATE          DATETIME,
  STATUS               INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (DA_DAILY_SUMMARYID),
  KEY IDX_DADAILY (ENTITYID, ROUTE_CODE, ITINERARY_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- CAPACITY_RELIABILITY and COMPLIANCE are nested/non-tabular Excel and
-- need custom row-scanning parsers before their tables are finalized.
