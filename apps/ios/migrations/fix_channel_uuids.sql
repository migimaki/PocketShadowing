-- SQL Script to Fix Channel UUIDs and Update Lesson References
-- Run this in Supabase SQL Editor

-- Step 1: Generate new UUIDs for channels
-- We'll use these specific UUIDs for each language:
-- English: a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d
-- Japanese: b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e
-- French: c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f

-- Step 2: Create a temporary mapping table
CREATE TEMP TABLE channel_mapping (
    old_id uuid,
    new_id uuid,
    language varchar
);

-- Insert the mappings
INSERT INTO channel_mapping (old_id, new_id, language) VALUES
    ('00000000-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d', 'en'),
    ('00000000-0000-0000-0000-000000000002', 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e', 'ja'),
    ('00000000-0000-0000-0000-000000000003', 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f', 'fr');

-- Step 3: Update channels table with new UUIDs
UPDATE channels
SET id = cm.new_id
FROM channel_mapping cm
WHERE channels.id = cm.old_id
  AND channels.language = cm.language;

-- Step 4: Update lessons to reference the correct channel based on language
UPDATE lessons
SET channel_id = cm.new_id
FROM channel_mapping cm
WHERE lessons.language = cm.language;

-- Step 5: Verify the updates
SELECT 'Channels after update:' as status;
SELECT id, name, language FROM channels ORDER BY language;

SELECT 'Lessons grouped by channel:' as status;
SELECT c.name as channel_name, c.language, COUNT(l.id) as lesson_count
FROM channels c
LEFT JOIN lessons l ON l.channel_id = c.id
GROUP BY c.id, c.name, c.language
ORDER BY c.language;

-- Step 6: Clean up
DROP TABLE channel_mapping;
