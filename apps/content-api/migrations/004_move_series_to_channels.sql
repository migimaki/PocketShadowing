-- Migration: Move series_id from lessons to channels table
-- Date: 2025-11-23
-- Purpose: Simplify data model - each channel represents one series in one language

-- Step 1: Add series_id to channels table
ALTER TABLE channels
ADD COLUMN IF NOT EXISTS series_id UUID REFERENCES series(id) ON DELETE SET NULL;

-- Step 2: Create index for performance
CREATE INDEX IF NOT EXISTS idx_channels_series_id ON channels(series_id);
CREATE INDEX IF NOT EXISTS idx_channels_language_series ON channels(language, series_id);

-- Step 3: Update existing channels to link to default "Euro News Daily" series
-- Assuming your current 3 channels should all link to the default series
UPDATE channels
SET series_id = '00000000-0000-0000-0000-000000000010'::UUID
WHERE series_id IS NULL;

-- Step 4: Remove series_id from lessons table (cleanup)
-- IMPORTANT: Run this AFTER verifying the above changes work correctly
-- Uncomment when ready:
-- ALTER TABLE lessons DROP COLUMN IF EXISTS series_id;

-- Step 5: Verification queries

-- Check channels with their series
SELECT
    c.id,
    c.title,
    c.language,
    c.series_id,
    s.name as series_name
FROM channels c
LEFT JOIN series s ON c.series_id = s.id
ORDER BY c.language, s.name;

-- Count lessons per channel
SELECT
    c.title as channel_title,
    c.language,
    s.name as series_name,
    COUNT(l.id) as lesson_count
FROM channels c
LEFT JOIN series s ON c.series_id = s.id
LEFT JOIN lessons l ON c.id = l.channel_id
GROUP BY c.id, c.title, c.language, s.name
ORDER BY c.language, s.name;

-- Check for any lessons still with series_id (before removal)
SELECT
    COUNT(*) as lessons_with_series_id,
    COUNT(DISTINCT series_id) as unique_series_ids
FROM lessons
WHERE series_id IS NOT NULL;

-- Verify all channels have a series
SELECT
    COUNT(*) as total_channels,
    COUNT(series_id) as channels_with_series,
    COUNT(*) - COUNT(series_id) as channels_without_series
FROM channels;

-- Show index information
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'channels'
    AND indexname LIKE '%series%'
ORDER BY indexname;
