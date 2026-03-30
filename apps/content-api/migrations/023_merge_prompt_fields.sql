-- Migration: Merge prompt fields into generation_prompt and tts_prompt
-- Description: Consolidates concept + ai_generation_prompt → generation_prompt,
--              and gemini_tts_prompt + gemini_tts_alt_prompt → tts_prompt
-- Date: 2026-03-30

-- Add new unified columns
ALTER TABLE series ADD COLUMN generation_prompt TEXT;
ALTER TABLE series ADD COLUMN tts_prompt TEXT;

-- Migrate text generation: concatenate concept and ai_generation_prompt
UPDATE series SET generation_prompt =
  CASE
    WHEN ai_generation_prompt IS NOT NULL AND ai_generation_prompt != ''
    THEN concept || E'\n\n' || ai_generation_prompt
    ELSE concept
  END;

-- Migrate TTS: use gemini_tts_prompt (alt prompt distinction removed by design)
UPDATE series SET tts_prompt = gemini_tts_prompt;

-- Make generation_prompt NOT NULL (concept was NOT NULL, so all rows have data)
ALTER TABLE series ALTER COLUMN generation_prompt SET NOT NULL;

-- Drop old columns
ALTER TABLE series DROP COLUMN concept;
ALTER TABLE series DROP COLUMN ai_generation_prompt;
ALTER TABLE series DROP COLUMN gemini_tts_prompt;
ALTER TABLE series DROP COLUMN gemini_tts_alt_prompt;
