-- Migration: Add title, subtitle, and description fields to channels table
-- Date: 2025-11-23
-- Purpose: Add metadata fields to channels for better content organization

-- Step 1: Add new columns to channels table
ALTER TABLE channels
ADD COLUMN IF NOT EXISTS title VARCHAR(255),
ADD COLUMN IF NOT EXISTS subtitle TEXT;

-- Note: description column might already exist as 'description'
-- Check if it exists, if not add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'channels' AND column_name = 'description'
    ) THEN
        ALTER TABLE channels ADD COLUMN description TEXT;
    END IF;
END $$;

-- Step 2: Optionally populate existing channels with default values
-- English Channel
UPDATE channels
SET
    title = 'English News',
    subtitle = 'Daily English language news and practice',
    description = 'Improve your English skills with daily news articles and conversations'
WHERE language = 'en' AND title IS NULL;

-- Japanese Channel
UPDATE channels
SET
    title = '日本語ニュース',
    subtitle = '毎日の日本語ニュースと練習',
    description = '毎日のニュース記事と会話で日本語スキルを向上させましょう'
WHERE language = 'ja' AND title IS NULL;

-- French Channel
UPDATE channels
SET
    title = 'Actualités en Français',
    subtitle = 'Actualités et pratique quotidiennes en français',
    description = 'Améliorez vos compétences en français avec des articles et des conversations quotidiennes'
WHERE language = 'fr' AND title IS NULL;

-- Step 3: Verification queries
SELECT
    id,
    name,
    language,
    title,
    subtitle,
    LEFT(description, 50) as description_preview
FROM channels
ORDER BY language;

-- Check column existence
SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'channels'
    AND column_name IN ('title', 'subtitle', 'description')
ORDER BY column_name;
