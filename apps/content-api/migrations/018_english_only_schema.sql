-- Migration 018: English-Only Schema Refactoring
--
-- Restructures the database for English-only learning with flexible translations.
-- Since we're starting fresh (no data to migrate), this drops old structures
-- and creates clean tables.
--
-- Changes:
--   - channels: remove language column (all channels are English)
--   - lessons: remove language and content_group_id columns
--   - series: remove multi-language TTS prompts, rename en prompts
--   - NEW: lesson_translations table for translated titles
--   - NEW: sentence_translations table for translated sentence text

-- ============================================================
-- Step 1: Drop dependent data (fresh start)
-- ============================================================

-- Delete all sentences (cascades won't help since we're altering tables)
DELETE FROM sentences;
DELETE FROM lessons;
DELETE FROM channels;

-- ============================================================
-- Step 2: Create new translation tables
-- ============================================================

CREATE TABLE IF NOT EXISTS lesson_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_lesson_translation UNIQUE (lesson_id, language)
);

CREATE INDEX idx_lesson_translations_lesson_lang ON lesson_translations(lesson_id, language);

CREATE TABLE IF NOT EXISTS sentence_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sentence_id UUID NOT NULL REFERENCES sentences(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_sentence_translation UNIQUE (sentence_id, language)
);

CREATE INDEX idx_sentence_translations_sentence_lang ON sentence_translations(sentence_id, language);

-- ============================================================
-- Step 3: Simplify lessons table
-- ============================================================

-- Drop old unique constraint
ALTER TABLE lessons DROP CONSTRAINT IF EXISTS unique_lesson_per_date_language_channel;

-- Drop language-related indexes
DROP INDEX IF EXISTS idx_lessons_language;
DROP INDEX IF EXISTS idx_lessons_language_date;
DROP INDEX IF EXISTS idx_lessons_content_group_id;

-- Drop columns
ALTER TABLE lessons DROP COLUMN IF EXISTS language;
ALTER TABLE lessons DROP COLUMN IF EXISTS content_group_id;

-- Add new unique constraint (one lesson per date per channel)
ALTER TABLE lessons ADD CONSTRAINT unique_lesson_per_date_channel UNIQUE (date, channel_id);

-- ============================================================
-- Step 4: Simplify channels table
-- ============================================================

-- Drop language-related indexes
DROP INDEX IF EXISTS idx_channels_language;
DROP INDEX IF EXISTS idx_channels_language_series;

-- Drop language column
ALTER TABLE channels DROP COLUMN IF EXISTS language;

-- ============================================================
-- Step 5: Simplify series table
-- ============================================================

-- Drop multi-language columns
ALTER TABLE series DROP COLUMN IF EXISTS supported_languages;
ALTER TABLE series DROP COLUMN IF EXISTS gemini_tts_prompt_ja;
ALTER TABLE series DROP COLUMN IF EXISTS gemini_tts_prompt_fr;
ALTER TABLE series DROP COLUMN IF EXISTS gemini_tts_alt_prompt_ja;
ALTER TABLE series DROP COLUMN IF EXISTS gemini_tts_alt_prompt_fr;

-- Drop language-related index
DROP INDEX IF EXISTS idx_series_languages;

-- Rename English-specific prompts to generic names
ALTER TABLE series RENAME COLUMN gemini_tts_prompt_en TO gemini_tts_prompt;
ALTER TABLE series RENAME COLUMN gemini_tts_alt_prompt_en TO gemini_tts_alt_prompt;
