-- Migration 021: Add channel_translations table
-- Date: 2026-02-16
-- Purpose: Support translated channel titles and descriptions for non-English users.
--          Follows the same pattern as lesson_translations.

CREATE TABLE IF NOT EXISTS channel_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_channel_translation UNIQUE (channel_id, language)
);

CREATE INDEX IF NOT EXISTS idx_channel_translations_channel_lang
  ON channel_translations(channel_id, language);

-- Enable RLS with public read access (same pattern as lesson_translations)
ALTER TABLE channel_translations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access"
  ON channel_translations
  FOR SELECT
  TO anon
  USING (true);
