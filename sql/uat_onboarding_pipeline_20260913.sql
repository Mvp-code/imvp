-- =============================================================================
-- UAT migration: DA Onboarding pipeline (S1–S7) + related columns
-- Date: 2026-09-13
-- DB: fleetdb (MySQL)
--
-- BEFORE RUNNING section 2 (data):
--   SELECT current_stage, COUNT(*) FROM da_onboarding GROUP BY current_stage;
--   SELECT config_key FROM mvpg_config WHERE config_key='ONBOARDING_STAGE_RENUMBER_V2';
--
--   • If you still see S8 or S9 (or no renumber flag) → run FULL script.
--   • If you already only have S1–S7 AND renumber flag exists → run section 1 only.
--
-- Section 2 is skipped automatically when ONBOARDING_STAGE_RENUMBER_V2 is present.
-- =============================================================================

USE fleetdb;

-- ---------------------------------------------------------------------------
-- 1) Schema
-- ---------------------------------------------------------------------------
-- Ignore "Duplicate column" errors if already applied.

ALTER TABLE da_onboarding
  ADD COLUMN drug_test_doc_path VARCHAR(500) NULL;

ALTER TABLE da_onboarding
  ADD COLUMN s6_notes TEXT NULL;

ALTER TABLE da_onboarding
  ADD COLUMN s7_notes TEXT NULL;

ALTER TABLE da_onboarding
  MODIFY COLUMN s3_result VARCHAR(500) NULL;

ALTER TABLE da_onboarding
  MODIFY COLUMN s5_result VARCHAR(500) NULL;

-- ---------------------------------------------------------------------------
-- 2) Data — only if renumber flag not set (old S1–S9 pipeline)
-- ---------------------------------------------------------------------------
SET @renumber_done := (
  SELECT COUNT(*) FROM mvpg_config
  WHERE config_key = 'ONBOARDING_STAGE_RENUMBER_V2' AND is_active = 'Y'
);

-- 2a) Old Drug Test stage S3 → S2
UPDATE da_onboarding
SET current_stage = 'S2'
WHERE @renumber_done = 0
  AND current_stage = 'S3';

UPDATE da_onboarding_stage_log
SET STAGE_CODE = 'S2'
WHERE @renumber_done = 0
  AND STAGE_CODE = 'S3';

-- 2b) Old Training S4/S5 → S3
UPDATE da_onboarding
SET current_stage = 'S3'
WHERE @renumber_done = 0
  AND current_stage IN ('S4', 'S5');

UPDATE da_onboarding_stage_log
SET STAGE_CODE = 'S3'
WHERE @renumber_done = 0
  AND STAGE_CODE IN ('S4', 'S5');

-- 2c) Old S6–S9 → S4–S7 (CASE uses original row values — collision-safe)
UPDATE da_onboarding
SET current_stage = CASE current_stage
  WHEN 'S9' THEN 'S7'
  WHEN 'S8' THEN 'S6'
  WHEN 'S7' THEN 'S5'
  WHEN 'S6' THEN 'S4'
  ELSE current_stage
END
WHERE @renumber_done = 0
  AND current_stage IN ('S6', 'S7', 'S8', 'S9');

UPDATE da_onboarding_stage_log
SET STAGE_CODE = CASE STAGE_CODE
  WHEN 'S9' THEN 'S7'
  WHEN 'S8' THEN 'S6'
  WHEN 'S7' THEN 'S5'
  WHEN 'S6' THEN 'S4'
  ELSE STAGE_CODE
END
WHERE @renumber_done = 0
  AND STAGE_CODE IN ('S6', 'S7', 'S8', 'S9');

INSERT INTO mvpg_config (
  config_id, entity_id, config_group, config_key, config_label,
  config_value, config_desc, is_active, CREATE_USER
)
SELECT
  (SELECT IFNULL(MAX(config_id), 0) + 1 FROM mvpg_config AS c2),
  1,
  'ONBOARDING',
  'ONBOARDING_STAGE_RENUMBER_V2',
  'Stage Renumber V2',
  'Y',
  'S6-S9 remapped to S4-S7',
  'Y',
  'SYSTEM'
FROM DUAL
WHERE @renumber_done = 0
  AND NOT EXISTS (
    SELECT 1 FROM mvpg_config WHERE config_key = 'ONBOARDING_STAGE_RENUMBER_V2'
  );

-- ---------------------------------------------------------------------------
-- 3) Verify — expect only S1..S7
-- ---------------------------------------------------------------------------
SELECT current_stage, COUNT(*) AS cnt
FROM da_onboarding
GROUP BY current_stage
ORDER BY current_stage;

SELECT config_id, config_key, config_value
FROM mvpg_config
WHERE config_key LIKE 'ONBOARDING_%'
ORDER BY config_key;
