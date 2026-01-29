-- SQL Script to Fix Channel UUIDs and Update Lesson References (Simple Version)
-- Run this in Supabase SQL Editor
-- This script updates channels based on language, regardless of current UUID

-- IMPORTANT: This assumes you have exactly 3 channels with languages: en, ja, fr

-- Step 1: Update English channel
UPDATE channels
SET id = 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d'
WHERE language = 'en';

-- Step 2: Update Japanese channel
UPDATE channels
SET id = 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e'
WHERE language = 'ja';

-- Step 3: Update French channel
UPDATE channels
SET id = 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f'
WHERE language = 'fr';

-- Step 4: Update English lessons to reference English channel
UPDATE lessons
SET channel_id = 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d'
WHERE language = 'en';

-- Step 5: Update Japanese lessons to reference Japanese channel
UPDATE lessons
SET channel_id = 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e'
WHERE language = 'ja';

-- Step 6: Update French lessons to reference French channel
UPDATE lessons
SET channel_id = 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f'
WHERE language = 'fr';

-- Step 7: Verify the updates
SELECT '=== Channels after update ===' as info;
SELECT id, name, language FROM channels ORDER BY language;

SELECT '=== Lessons count by channel ===' as info;
SELECT
    c.name as channel_name,
    c.language,
    c.id as channel_id,
    COUNT(l.id) as lesson_count
FROM channels c
LEFT JOIN lessons l ON l.channel_id = c.id
GROUP BY c.id, c.name, c.language
ORDER BY c.language;
