-- Migration 016: Add Voice Name Columns for Gemini-TTS Alternation
-- Description: Adds default_voice_name and alternate_voice_name columns to support
--              voice alternation with Gemini-TTS speaker names.
--              Voice names are language-agnostic in Gemini-TTS.
-- Date: 2025-12-06
-- Author: Claude Code

-- =============================================================================
-- Step 1: Create enum type for valid Gemini-TTS voices
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE gemini_tts_voice AS ENUM (
        -- Female voices (14 total)
        'Achernar', 'Aoede', 'Autonoe', 'Callirrhoe', 'Despina',
        'Erinome', 'Gacrux', 'Kore', 'Laomedeia', 'Leda',
        'Pulcherrima', 'Sulafat', 'Vindemiatrix', 'Zephyr',
        -- Male voices (16 total)
        'Achird', 'Algenib', 'Algieba', 'Alnilam', 'Charon',
        'Enceladus', 'Fenrir', 'Iapetus', 'Orus', 'Puck',
        'Rasalgethi', 'Sadachbia', 'Sadaltager', 'Schedar',
        'Umbriel', 'Zubenelgenubi'
    );
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Type gemini_tts_voice already exists, skipping creation';
END $$;

-- =============================================================================
-- Step 2: Add voice name columns to series table
-- =============================================================================

ALTER TABLE series
ADD COLUMN IF NOT EXISTS default_voice_name gemini_tts_voice DEFAULT 'Charon',
ADD COLUMN IF NOT EXISTS alternate_voice_name gemini_tts_voice;

-- =============================================================================
-- Step 3: Add comments for documentation
-- =============================================================================

COMMENT ON COLUMN series.default_voice_name IS 'Gemini-TTS speaker name for default voice (applies to all languages). Used for odd-numbered sentences (0, 2, 4...) or all sentences when alternation disabled. Defaults to Charon (male, clear voice).';
COMMENT ON COLUMN series.alternate_voice_name IS 'Gemini-TTS speaker name for alternate voice (applies to all languages). Used for even-numbered sentences (1, 3, 5...) when enable_voice_alternation is true. Falls back to Kore if NULL and alternation enabled.';

-- =============================================================================
-- Step 4: Create indexes for voice queries
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_series_default_voice
ON series(default_voice_name);

CREATE INDEX IF NOT EXISTS idx_series_alternate_voice
ON series(alternate_voice_name)
WHERE alternate_voice_name IS NOT NULL;

-- =============================================================================
-- Step 5: Update existing series with appropriate default values
-- =============================================================================

-- Series with alternation enabled should get both voices set (Charon + Kore)
UPDATE series
SET
    default_voice_name = 'Charon',
    alternate_voice_name = 'Kore'
WHERE enable_voice_alternation = true
  AND (default_voice_name IS NULL OR alternate_voice_name IS NULL);

-- Series without alternation should get only default voice (Charon)
UPDATE series
SET default_voice_name = 'Charon'
WHERE enable_voice_alternation = false
  AND default_voice_name IS NULL;

-- =============================================================================
-- Step 6: Verification and Statistics
-- =============================================================================

-- Display migration results
DO $$
DECLARE
    total_series INTEGER;
    series_with_alternation INTEGER;
    series_without_alternation INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_series FROM series;
    SELECT COUNT(*) INTO series_with_alternation FROM series WHERE enable_voice_alternation = true;
    SELECT COUNT(*) INTO series_without_alternation FROM series WHERE enable_voice_alternation = false;

    RAISE NOTICE '=== Migration 016 Results ===';
    RAISE NOTICE 'Total series: %', total_series;
    RAISE NOTICE 'Series with voice alternation enabled: %', series_with_alternation;
    RAISE NOTICE 'Series without voice alternation: %', series_without_alternation;
    RAISE NOTICE 'Migration completed successfully!';
END $$;

-- Display current voice configuration
SELECT
    name,
    enable_voice_alternation,
    default_voice_name,
    alternate_voice_name,
    gemini_tts_prompt IS NOT NULL as has_default_prompt,
    gemini_tts_alt_prompt IS NOT NULL as has_alt_prompt
FROM series
ORDER BY name;

-- =============================================================================
-- Rollback Instructions (run in reverse order if needed)
-- =============================================================================
--
-- To rollback this migration, run these commands:
--
-- ALTER TABLE series DROP COLUMN IF EXISTS alternate_voice_name;
-- ALTER TABLE series DROP COLUMN IF EXISTS default_voice_name;
-- DROP TYPE IF EXISTS gemini_tts_voice;
--
-- Note: This will remove all voice configuration data. Backup before rollback!
-- =============================================================================
