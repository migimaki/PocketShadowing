-- Migration: Add cover_image_url to channels table
-- Date: 2025-11-23
-- Purpose: Allow channels to display series cover images

-- Step 1: Add cover_image_url column to channels
ALTER TABLE channels
ADD COLUMN IF NOT EXISTS cover_image_url VARCHAR(500);

-- Step 2: Create index for performance (optional)
CREATE INDEX IF NOT EXISTS idx_channels_cover_image ON channels(cover_image_url) WHERE cover_image_url IS NOT NULL;

-- Step 3: Update existing channels with their series cover images
UPDATE channels c
SET cover_image_url = s.cover_image_url
FROM series s
WHERE c.series_id = s.id
  AND s.cover_image_url IS NOT NULL
  AND c.cover_image_url IS NULL;

-- Verification queries

-- Check channels with cover images
SELECT
    c.id,
    c.title,
    c.language,
    c.cover_image_url,
    s.name as series_name,
    s.cover_image_url as series_cover_image
FROM channels c
LEFT JOIN series s ON c.series_id = s.id
ORDER BY c.language;

-- Count channels with/without cover images
SELECT
    COUNT(*) as total_channels,
    COUNT(cover_image_url) as channels_with_cover,
    COUNT(*) - COUNT(cover_image_url) as channels_without_cover
FROM channels;
