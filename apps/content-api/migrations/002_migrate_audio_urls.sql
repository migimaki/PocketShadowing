-- Migration: Update audio URLs to new path structure
-- Description: Updates all sentence audio_url values to new multi-language path format
-- Date: 2025-11-14
-- IMPORTANT: Run this AFTER migrating audio files in Supabase Storage

-- ============================================
-- Update audio URLs for existing English content
-- ============================================

-- This query updates the audio_url column to use the new path structure:
-- Old format: 2025-11-14/line_001.mp3
-- New format: en/euro-news/2025-11-14/line_001.mp3

UPDATE sentences
SET audio_url = REGEXP_REPLACE(
  audio_url,
  '([0-9]{4}-[0-9]{2}-[0-9]{2})/line_',
  'en/euro-news/\1/line_',
  'g'
)
WHERE audio_url LIKE '%/line_%'
  AND audio_url NOT LIKE '%/en/euro-news/%'
  AND audio_url NOT LIKE '%/ja/euro-news/%'
  AND audio_url NOT LIKE '%/fr/euro-news/%';

-- ============================================
-- Verification Query
-- ============================================

-- Run this to verify the migration was successful:
-- SELECT
--   audio_url,
--   CASE
--     WHEN audio_url LIKE '%/en/euro-news/%' THEN 'Migrated'
--     WHEN audio_url LIKE '%/ja/euro-news/%' THEN 'Migrated'
--     WHEN audio_url LIKE '%/fr/euro-news/%' THEN 'Migrated'
--     ELSE 'Not Migrated'
--   END as migration_status
-- FROM sentences
-- ORDER BY migration_status, audio_url;

-- ============================================
-- Rollback
-- ============================================

-- To rollback (restore old URLs):
-- UPDATE sentences
-- SET audio_url = REGEXP_REPLACE(
--   audio_url,
--   'en/euro-news/([0-9]{4}-[0-9]{2}-[0-9]{2})/line_',
--   '\1/line_',
--   'g'
-- )
-- WHERE audio_url LIKE '%/en/euro-news/%/line_%';
