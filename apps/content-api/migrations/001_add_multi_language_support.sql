-- Migration: Add Multi-Language Support
-- Description: Add language support for English, Japanese, and French
-- Date: 2025-11-14

-- ============================================
-- Step 1: Create channels table
-- ============================================
CREATE TABLE IF NOT EXISTS channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  language VARCHAR(10) NOT NULL,
  icon_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on language for faster queries
CREATE INDEX IF NOT EXISTS idx_channels_language ON channels(language);

-- ============================================
-- Step 2: Insert default channels
-- ============================================
INSERT INTO channels (id, name, description, language, icon_name)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Euro News', 'Daily English lessons based on special days and events', 'en', 'globe'),
  ('00000000-0000-0000-0000-000000000002', 'Euro News', 'Japanese lessons based on special days and events (ユーロニュース)', 'ja', 'globe'),
  ('00000000-0000-0000-0000-000000000003', 'Euro News', 'French lessons based on special days and events (Actualités Euro)', 'fr', 'globe')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Step 3: Add new columns to lessons table
-- ============================================

-- Add language column (default to 'en' for existing records)
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'en' NOT NULL;

-- Add channel_id column
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS channel_id UUID;

-- Backfill channel_id for existing English lessons
UPDATE lessons
SET channel_id = '00000000-0000-0000-0000-000000000001'
WHERE channel_id IS NULL;

-- Make channel_id NOT NULL after backfill
ALTER TABLE lessons
ALTER COLUMN channel_id SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE lessons
ADD CONSTRAINT fk_lessons_channel_id
FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE;

-- ============================================
-- Step 4: Update constraints
-- ============================================

-- Drop the existing unique constraint on date (if it exists)
-- Note: Constraint name might vary, adjust if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'lessons_date_key'
    AND conrelid = 'lessons'::regclass
  ) THEN
    ALTER TABLE lessons DROP CONSTRAINT lessons_date_key;
  END IF;
END $$;

-- Add new unique constraint on (date, language, channel_id)
-- This allows the same date to have lessons in different languages
ALTER TABLE lessons
ADD CONSTRAINT unique_lesson_per_date_language_channel
UNIQUE (date, language, channel_id);

-- ============================================
-- Step 5: Create indexes for better performance
-- ============================================

-- Index on language for filtering lessons by language
CREATE INDEX IF NOT EXISTS idx_lessons_language ON lessons(language);

-- Index on channel_id for filtering lessons by channel
CREATE INDEX IF NOT EXISTS idx_lessons_channel_id ON lessons(channel_id);

-- Composite index for common query pattern (language + date)
CREATE INDEX IF NOT EXISTS idx_lessons_language_date ON lessons(language, date DESC);

-- ============================================
-- Step 6: Migration notes
-- ============================================

-- IMPORTANT: After running this migration, you need to:
--
-- 1. Migrate audio files in Supabase Storage:
--    - Current path: YYYY-MM-DD/line_XXX.mp3
--    - New path: en/euro-news/YYYY-MM-DD/line_XXX.mp3
--    - This must be done using Supabase Storage API or dashboard
--
-- 2. Update audio_url in sentences table to reflect new paths:
--    UPDATE sentences
--    SET audio_url = REPLACE(audio_url, '/YYYY-MM-DD/', '/en/euro-news/YYYY-MM-DD/')
--    WHERE audio_url LIKE '%/YYYY-MM-DD/%';
--
--    Note: You may need to do this per date or use a more sophisticated
--    approach depending on how many records exist.
--
-- 3. Deploy updated Node.js content generator that generates content
--    for all 3 languages (en, ja, fr)
--
-- 4. Deploy updated iOS app that filters lessons by user's selected
--    learning language preference

-- ============================================
-- Rollback (if needed)
-- ============================================

-- To rollback this migration, run:
--
-- ALTER TABLE lessons DROP CONSTRAINT IF EXISTS unique_lesson_per_date_language_channel;
-- ALTER TABLE lessons DROP CONSTRAINT IF EXISTS fk_lessons_channel_id;
-- ALTER TABLE lessons DROP COLUMN IF EXISTS channel_id;
-- ALTER TABLE lessons DROP COLUMN IF EXISTS language;
-- DROP INDEX IF EXISTS idx_lessons_language;
-- DROP INDEX IF EXISTS idx_lessons_channel_id;
-- DROP INDEX IF EXISTS idx_lessons_language_date;
-- DROP INDEX IF EXISTS idx_channels_language;
-- DROP TABLE IF EXISTS channels;
--
-- Then restore original unique constraint:
-- ALTER TABLE lessons ADD CONSTRAINT lessons_date_key UNIQUE (date);
