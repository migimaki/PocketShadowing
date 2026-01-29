-- Migration: Remove Obsolete Voice Columns
-- Description: Removes Google Cloud TTS voice configuration columns that are no longer needed
--              with Gemini-TTS implementation. Gemini-TTS uses speaker names directly from
--              configuration and custom prompts instead of mapping from old voice names.
-- Date: 2025-11-28

-- Remove old Google Cloud TTS voice configuration columns
ALTER TABLE series
DROP COLUMN IF EXISTS default_voice_en,
DROP COLUMN IF EXISTS default_voice_ja,
DROP COLUMN IF EXISTS default_voice_fr,
DROP COLUMN IF EXISTS alternate_voice_en,
DROP COLUMN IF EXISTS alternate_voice_ja,
DROP COLUMN IF EXISTS alternate_voice_fr,
DROP COLUMN IF EXISTS voice_alternation_pattern;

-- Keep: enable_voice_alternation (still used to determine if we should alternate speakers)
-- Keep: gemini_tts_prompt_* columns (used for custom prompts)

-- Add comment to document the cleanup
COMMENT ON TABLE series IS 'Series configuration for content generation. Voice configuration migrated to Gemini-TTS with custom prompts (gemini_tts_prompt_* columns) instead of voice name mappings.';
