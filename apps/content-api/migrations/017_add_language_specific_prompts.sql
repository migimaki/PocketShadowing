-- Migration 017: Add Language-Specific Gemini-TTS Prompts
-- Description: Converts unified Gemini-TTS prompts to language-specific prompts
--              for English, Japanese, and French. Enables better voice control
--              customized for each language's unique characteristics.
-- Date: 2025-12-06
-- Author: Claude Code
-- Reverses: Migration 010 (simplify_prompts_to_single_column.sql)

-- =============================================================================
-- Step 1: Add 6 new language-specific prompt columns
-- =============================================================================

ALTER TABLE series
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_en TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_ja TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_fr TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_en TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_ja TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_fr TEXT;

-- =============================================================================
-- Step 2: Migrate existing data (preserve unified prompts by copying to all languages)
-- =============================================================================

-- Copy unified default prompt to all language columns
UPDATE series
SET gemini_tts_prompt_en = gemini_tts_prompt,
    gemini_tts_prompt_ja = gemini_tts_prompt,
    gemini_tts_prompt_fr = gemini_tts_prompt
WHERE gemini_tts_prompt IS NOT NULL;

-- Copy unified alternate prompt to all language columns
UPDATE series
SET gemini_tts_alt_prompt_en = gemini_tts_alt_prompt,
    gemini_tts_alt_prompt_ja = gemini_tts_alt_prompt,
    gemini_tts_alt_prompt_fr = gemini_tts_alt_prompt
WHERE gemini_tts_alt_prompt IS NOT NULL;

-- =============================================================================
-- Step 3: Drop old unified columns
-- =============================================================================

ALTER TABLE series
DROP COLUMN IF EXISTS gemini_tts_prompt,
DROP COLUMN IF EXISTS gemini_tts_alt_prompt;

-- =============================================================================
-- Step 4: Add comments for documentation
-- =============================================================================

COMMENT ON COLUMN series.gemini_tts_prompt_en IS 'English-specific prompt for default voice TTS generation. Describes tone, pacing, and delivery style.';
COMMENT ON COLUMN series.gemini_tts_prompt_ja IS 'Japanese-specific prompt for default voice TTS generation. Describes tone, pacing, and delivery style.';
COMMENT ON COLUMN series.gemini_tts_prompt_fr IS 'French-specific prompt for default voice TTS generation. Describes tone, pacing, and delivery style.';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_en IS 'English-specific prompt for alternate voice TTS generation (when voice_alternation enabled). Creates conversational dialogue.';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_ja IS 'Japanese-specific prompt for alternate voice TTS generation (when voice_alternation enabled). Creates conversational dialogue.';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_fr IS 'French-specific prompt for alternate voice TTS generation (when voice_alternation enabled). Creates conversational dialogue.';

-- =============================================================================
-- Step 5: Verification and Statistics
-- =============================================================================

-- Display migration results
DO $$
DECLARE
    total_series INTEGER;
    series_with_prompts_en INTEGER;
    series_with_prompts_ja INTEGER;
    series_with_prompts_fr INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_series FROM series;
    SELECT COUNT(*) INTO series_with_prompts_en FROM series WHERE gemini_tts_prompt_en IS NOT NULL;
    SELECT COUNT(*) INTO series_with_prompts_ja FROM series WHERE gemini_tts_prompt_ja IS NOT NULL;
    SELECT COUNT(*) INTO series_with_prompts_fr FROM series WHERE gemini_tts_prompt_fr IS NOT NULL;

    RAISE NOTICE '=== Migration 017 Results ===';
    RAISE NOTICE 'Total series: %', total_series;
    RAISE NOTICE 'Series with English prompts: %', series_with_prompts_en;
    RAISE NOTICE 'Series with Japanese prompts: %', series_with_prompts_ja;
    RAISE NOTICE 'Series with French prompts: %', series_with_prompts_fr;
    RAISE NOTICE 'Migration completed successfully!';
END $$;

-- Display sample of migrated data
SELECT
    id,
    name,
    gemini_tts_prompt_en IS NOT NULL as has_en_prompt,
    gemini_tts_prompt_ja IS NOT NULL as has_ja_prompt,
    gemini_tts_prompt_fr IS NOT NULL as has_fr_prompt,
    gemini_tts_alt_prompt_en IS NOT NULL as has_en_alt,
    gemini_tts_alt_prompt_ja IS NOT NULL as has_ja_alt,
    gemini_tts_alt_prompt_fr IS NOT NULL as has_fr_alt
FROM series
ORDER BY name
LIMIT 10;

-- =============================================================================
-- Rollback Instructions (run if migration needs to be reversed)
-- =============================================================================
--
-- To rollback this migration, run these commands:
--
-- -- Add back unified columns
-- ALTER TABLE series
-- ADD COLUMN IF NOT EXISTS gemini_tts_prompt TEXT,
-- ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt TEXT;
--
-- -- Merge language-specific back to unified (use COALESCE to pick first non-NULL)
-- UPDATE series
-- SET gemini_tts_prompt = COALESCE(
--   gemini_tts_prompt_en,
--   gemini_tts_prompt_ja,
--   gemini_tts_prompt_fr
-- );
--
-- UPDATE series
-- SET gemini_tts_alt_prompt = COALESCE(
--   gemini_tts_alt_prompt_en,
--   gemini_tts_alt_prompt_ja,
--   gemini_tts_alt_prompt_fr
-- );
--
-- -- Drop language-specific columns
-- ALTER TABLE series
-- DROP COLUMN gemini_tts_prompt_en,
-- DROP COLUMN gemini_tts_prompt_ja,
-- DROP COLUMN gemini_tts_prompt_fr,
-- DROP COLUMN gemini_tts_alt_prompt_en,
-- DROP COLUMN gemini_tts_alt_prompt_ja,
-- DROP COLUMN gemini_tts_alt_prompt_fr;
--
-- Note: Rollback will use English prompts if all language prompts are set.
--       This preserves data but may not restore exact original state.
-- =============================================================================
