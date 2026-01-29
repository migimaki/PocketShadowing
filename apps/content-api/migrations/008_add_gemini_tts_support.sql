-- Migration: Add Gemini-TTS Support
-- Description: Adds Gemini-TTS prompt columns to series table for custom voice prompts
-- Date: 2025-01-28

-- Add Gemini-TTS prompt columns to series table
-- These fields allow series to customize the natural language prompts
-- used by Gemini-TTS for more contextual and emotional voice output

ALTER TABLE series
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_en TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_ja TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_prompt_fr TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_en TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_ja TEXT,
ADD COLUMN IF NOT EXISTS gemini_tts_alt_prompt_fr TEXT;

-- Optional: Populate default prompts for existing series
-- This ensures existing series have sensible default prompts
-- Uses intermediate-level prompts as a reasonable default

UPDATE series
SET
  gemini_tts_prompt_en = 'Speak naturally with expressive intonation. Sound conversational but clear.',
  gemini_tts_prompt_ja = '自然なペースで話してください。表現力豊かなイントネーションを使用してください。',
  gemini_tts_prompt_fr = 'Parlez naturellement avec une intonation expressive. Soyez conversationnel mais clair.'
WHERE gemini_tts_prompt_en IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN series.gemini_tts_prompt_en IS 'Custom Gemini-TTS prompt for English voice output (default speaker)';
COMMENT ON COLUMN series.gemini_tts_prompt_ja IS 'Custom Gemini-TTS prompt for Japanese voice output (default speaker)';
COMMENT ON COLUMN series.gemini_tts_prompt_fr IS 'Custom Gemini-TTS prompt for French voice output (default speaker)';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_en IS 'Custom Gemini-TTS prompt for English voice output (alternate speaker)';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_ja IS 'Custom Gemini-TTS prompt for Japanese voice output (alternate speaker)';
COMMENT ON COLUMN series.gemini_tts_alt_prompt_fr IS 'Custom Gemini-TTS prompt for French voice output (alternate speaker)';
