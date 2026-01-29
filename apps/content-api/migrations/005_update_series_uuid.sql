-- Migration: Replace test-looking series UUID with proper random UUID
-- Date: 2025-11-23
-- Purpose: Update default series ID from test UUID to proper random UUID

-- Old ID: 00000000-0000-0000-0000-000000000010
-- New ID: d4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a

DO $$
DECLARE
    old_series_id UUID := '00000000-0000-0000-0000-000000000010';
    new_series_id UUID := 'd4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a';
    affected_channels INT;
    series_record RECORD;
BEGIN
    -- Step 1: Get the old series data
    RAISE NOTICE 'Fetching old series data...';
    SELECT * INTO series_record FROM series WHERE id = old_series_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error: Series with old ID not found';
    END IF;

    -- Step 2: Create new series with new ID and same data
    RAISE NOTICE 'Creating new series with new ID...';
    INSERT INTO series (
        id,
        name,
        concept,
        cover_image_url,
        word_count,
        difficulty_level,
        supported_languages,
        ai_generation_prompt,
        created_at,
        updated_at
    ) VALUES (
        new_series_id,
        series_record.name,
        series_record.concept,
        series_record.cover_image_url,
        series_record.word_count,
        series_record.difficulty_level,
        series_record.supported_languages,
        series_record.ai_generation_prompt,
        series_record.created_at,
        NOW()
    );

    -- Step 3: Update channels to reference new series
    RAISE NOTICE 'Updating channels to reference new series...';
    UPDATE channels
    SET series_id = new_series_id
    WHERE series_id = old_series_id;

    GET DIAGNOSTICS affected_channels = ROW_COUNT;
    RAISE NOTICE 'Updated % channels', affected_channels;

    -- Step 4: Delete old series (now that nothing references it)
    RAISE NOTICE 'Deleting old series...';
    DELETE FROM series WHERE id = old_series_id;

    -- Step 5: Verify
    IF EXISTS (SELECT 1 FROM channels WHERE series_id = old_series_id) THEN
        RAISE EXCEPTION 'Error: Some channels still reference old series ID';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM series WHERE id = new_series_id) THEN
        RAISE EXCEPTION 'Error: New series not found';
    END IF;

    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE 'New Series ID: %', new_series_id;
END $$;

-- Verification queries
-- Check the updated series
SELECT
    id,
    name,
    concept,
    difficulty_level,
    word_count
FROM series
WHERE id = 'd4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a';

-- Check all channels now reference the new ID
SELECT
    c.id,
    c.title,
    c.language,
    c.series_id,
    s.name as series_name
FROM channels c
LEFT JOIN series s ON c.series_id = s.id
WHERE c.series_id = 'd4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a'
ORDER BY c.language;

-- Verify no orphaned references
SELECT
    COUNT(*) as total_channels,
    COUNT(series_id) as channels_with_series,
    COUNT(*) - COUNT(series_id) as channels_without_series
FROM channels;

-- Summary
SELECT
    's.id has been updated to: d4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a' as summary;
