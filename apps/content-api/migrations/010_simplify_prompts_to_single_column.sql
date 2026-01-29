-- Migration: Simplify Gemini-TTS Prompts to Single Column
-- Description: Replace 6 language-specific prompt columns with 2 unified columns.
--              English prompts work well for all languages in Gemini-TTS.
--              This simplifies maintenance and ensures consistent tone across languages.
-- Date: 2025-11-28

-- Add new unified prompt columns
ALTER TABLE series
ADD COLUMN IF NOT EXISTS gemini_tts_prompt TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt TEXT;

-- Migrate existing data from language-specific columns to unified columns
-- Priority: en > ja > fr (take first non-null value)
UPDATE series
SET
  gemini_tts_prompt = COALESCE(gemini_tts_prompt_en, gemini_tts_prompt_ja, gemini_tts_prompt_fr),
  gemini_tts_alt_prompt = COALESCE(gemini_tts_alt_prompt_en, gemini_tts_alt_prompt_ja, gemini_tts_alt_prompt_fr)
WHERE gemini_tts_prompt_en IS NOT NULL
   OR gemini_tts_prompt_ja IS NOT NULL
   OR gemini_tts_prompt_fr IS NOT NULL
   OR gemini_tts_alt_prompt_en IS NOT NULL
   OR gemini_tts_alt_prompt_ja IS NOT NULL
   OR gemini_tts_alt_prompt_fr IS NOT NULL;

-- Remove old language-specific columns
ALTER TABLE series
DROP COLUMN IF EXISTS gemini_tts_prompt_en,
DROP COLUMN IF EXISTS gemini_tts_prompt_ja,
DROP COLUMN IF EXISTS gemini_tts_prompt_fr,
DROP COLUMN IF EXISTS gemini_tts_alt_prompt_en,
DROP COLUMN IF EXISTS gemini_tts_alt_prompt_ja,
DROP COLUMN IF EXISTS gemini_tts_alt_prompt_fr;

-- Add comments for documentation
COMMENT ON COLUMN series.gemini_tts_prompt IS 'Gemini-TTS prompt for default speaker (applies to all languages). Example: "Speak naturally with expressive intonation."';
COMMENT ON COLUMN series.gemini_tts_alt_prompt IS 'Gemini-TTS prompt for alternate speaker when voice alternation is enabled. Example: "Speak as a different person with a warm tone."';
