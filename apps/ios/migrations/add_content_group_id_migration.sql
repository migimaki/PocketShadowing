-- SQL Migration: Add content_group_id to lessons table
-- This field links lessons with the same content across different languages
-- Run this in Supabase SQL Editor

BEGIN;

-- Step 1: Add content_group_id column to lessons table
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS content_group_id UUID;

-- Step 2: Create an index for faster queries
CREATE INDEX IF NOT EXISTS idx_lessons_content_group_id
ON lessons(content_group_id);

-- Step 3: Generate content_group_id for existing lessons
-- Group lessons by date (assuming lessons on the same date are translations)
-- You may need to adjust this logic based on your data

-- Create a temporary table to store the mapping
CREATE TEMP TABLE lesson_groups AS
SELECT
    date,
    gen_random_uuid() as group_id
FROM lessons
GROUP BY date;

-- Update lessons with the generated group_id
UPDATE lessons l
SET content_group_id = lg.group_id
FROM lesson_groups lg
WHERE l.date = lg.date;

-- Step 4: Verify the updates
SELECT '=== Lessons grouped by content_group_id ===' as info;
SELECT
    content_group_id,
    COUNT(*) as lesson_count,
    STRING_AGG(DISTINCT language, ', ') as languages,
    MIN(date) as date,
    MIN(title) as sample_title
FROM lessons
WHERE content_group_id IS NOT NULL
GROUP BY content_group_id
ORDER BY date DESC
LIMIT 10;

-- Step 5: Check if any lessons don't have a group_id
SELECT '=== Lessons without content_group_id ===' as info;
SELECT COUNT(*) as ungrouped_lessons
FROM lessons
WHERE content_group_id IS NULL;

COMMIT;

-- Note: After running this migration, when creating new lessons in the future,
-- make sure to:
-- 1. Generate a new content_group_id for the English lesson
-- 2. Use the same content_group_id for Japanese and French translations
