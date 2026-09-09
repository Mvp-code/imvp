-- ============================================================
--  USER_PREFERENCES
--  Per-user UI preferences: theme color, language, accessibility.
--  One row per user per tenant (entity). Source of truth for the
--  client-side preferences engine (mvpx-prefs.js) so a user's
--  choices follow them across browsers and devices.
--
--  STATUS uses RecordStatus convention: 0 = ACTIVE, 1 = DELETE.
-- ============================================================

USE fleetdb;

CREATE TABLE IF NOT EXISTS fleetdb.USER_PREFERENCES (
  USERPREFERENCEID  INT(11)      NOT NULL,                    -- assigned by app via NEXTVAL('USERPREFERENCEID')
  USERID            VARCHAR(100) NOT NULL,                    -- = ENTITYUSERSID (loginUserID); falls back to loginUser
  ENTITYID          INT(11)      NOT NULL DEFAULT 1,          -- tenant (defaults to 1)
  STATION           VARCHAR(50)  DEFAULT NULL,                -- station code (forward-looking; multi-station)
  EMPLOYEEID        INT(11)      DEFAULT NULL,                -- ENTITYUSERS.EMPLOYEEID -> EMPLOYEE
  TRANSPORTERID     VARCHAR(50)  DEFAULT NULL,                -- EMPLOYEE.TRANSPORTERID (Amazon DA id)
  THEME             VARCHAR(20)  NOT NULL DEFAULT 'blue',     -- blue | green | purple | slate | orange
  LANG              VARCHAR(10)  NOT NULL DEFAULT 'en',       -- en | es
  FONT_SCALE        VARCHAR(10)  NOT NULL DEFAULT '1',        -- reserved for future multi-step font sizing
  A11Y_LARGE        TINYINT(1)   NOT NULL DEFAULT 0,          -- larger text
  A11Y_CONTRAST     TINYINT(1)   NOT NULL DEFAULT 0,          -- high contrast
  A11Y_MOTION       TINYINT(1)   NOT NULL DEFAULT 0,          -- reduce motion
  CREATE_USER       VARCHAR(100) DEFAULT 'system',                                  -- default user when app doesn't supply one
  CREATE_DATE       DATETIME     DEFAULT CURRENT_TIMESTAMP,                          -- defaults to now
  UPDATE_USER       VARCHAR(100) DEFAULT NULL,
  UPDATE_DATE       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- auto-set on every change
  STATUS            INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (USERPREFERENCEID),
  UNIQUE KEY UQ_USERPREF_USER_ENTITY (USERID, ENTITYID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
--  Register the sequence used for the PK (same mechanism as every
--  other *ID in this schema, e.g. PHONEID, EMPLOYEEID).
--  The app calls SELECT NEXTVAL('USERPREFERENCEID').
--
--  seq table columns are (name, val). Seeded at 0 so the first NEXTVAL
--  returns 1. Safe to re-run.
-- ------------------------------------------------------------
INSERT INTO fleetdb.seq (name, val) VALUES ('USERPREFERENCEID', 0)
  ON DUPLICATE KEY UPDATE name = name;

