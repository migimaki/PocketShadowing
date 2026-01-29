-- SQL Script to Fix Channel UUIDs - Version 2 (Handles Foreign Key Constraints)
-- Run this in Supabase SQL Editor

-- This approach:
-- 1. Creates new channels with proper UUIDs
-- 2. Updates lessons to reference new channels
-- 3. Deletes old placeholder channels

BEGIN;

-- Step 1: Create new channels with proper UUIDs
INSERT INTO channels (id, name, description, icon_name, language, created_at)
VALUES
    ('a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d', 'Euro News', 'Daily English lessons based on special days and events', 'globe.europe.africa.fill', 'en', NOW()),
    ('b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e', 'Euro News', 'Japanese lessons based on special days and events (ユーロニュース)', 'globe.europe.africa.fill', 'ja', NOW()),
    ('c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f', 'Euro News', 'French lessons based on special days and events (Actualités Euro)', 'globe.europe.africa.fill', 'fr', NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 2: Update English lessons to reference new English channel
UPDATE lessons
SET channel_id = 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d'
WHERE language = 'en';

-- Step 3: Update Japanese lessons to reference new Japanese channel
UPDATE lessons
SET channel_id = 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e'
WHERE language = 'ja';

-- Step 4: Update French lessons to reference new French channel
UPDATE lessons
SET channel_id = 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f'
WHERE language = 'fr';

-- Step 5: Delete old placeholder channels (now that no lessons reference them)
DELETE FROM channels
WHERE id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003'
);

COMMIT;

-- Step 6: Verify the updates
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

SELECT '=== Sample lessons (first 5) ===' as info;
SELECT l.id, l.title, l.language, l.channel_id, c.name as channel_name
FROM lessons l
JOIN channels c ON l.channel_id = c.id
ORDER BY l.language, l.date DESC
LIMIT 5;
