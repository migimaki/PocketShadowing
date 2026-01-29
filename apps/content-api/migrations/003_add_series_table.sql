-- Migration: Add Series table for content management
-- Date: 2025-11-23
-- Purpose: Create Series table to systematically manage content creation with AI

-- Step 1: Create Series table
CREATE TABLE IF NOT EXISTS series (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    concept TEXT NOT NULL,
    cover_image_url VARCHAR(500),
    word_count INT NOT NULL DEFAULT 150,
    difficulty_level VARCHAR(50) NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    supported_languages VARCHAR(10)[] NOT NULL DEFAULT ARRAY['en', 'ja', 'fr']::VARCHAR[],
    ai_generation_prompt TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Add series_id to lessons table
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS series_id UUID REFERENCES series(id) ON DELETE SET NULL;

-- Step 3: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_lessons_series_id ON lessons(series_id);
CREATE INDEX IF NOT EXISTS idx_series_difficulty ON series(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_series_languages ON series USING GIN(supported_languages);

-- Step 4: Create default "Euro News Daily" series
INSERT INTO series (
    id,
    name,
    concept,
    word_count,
    difficulty_level,
    supported_languages,
    ai_generation_prompt
) VALUES (
    '00000000-0000-0000-0000-000000000010'::UUID,
    'Euro News Daily',
    'Daily news content about special days, current events, and interesting facts from around the world. Designed for language learners to practice listening and speaking skills with real-world content.',
    150,
    'intermediate',
    ARRAY['en', 'ja', 'fr']::VARCHAR[],
    'Generate conversational news content about special days and current events. Focus on natural speech patterns suitable for language learning. Use simple yet engaging language appropriate for intermediate learners. Include interesting facts and cultural context.'
) ON CONFLICT (id) DO NOTHING;

-- Step 5: Migrate existing lessons to default series
UPDATE lessons
SET series_id = '00000000-0000-0000-0000-000000000010'::UUID
WHERE series_id IS NULL;

-- Step 6: Add updated_at trigger for series table
CREATE OR REPLACE FUNCTION update_series_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER series_updated_at_trigger
    BEFORE UPDATE ON series
    FOR EACH ROW
    EXECUTE FUNCTION update_series_updated_at();

-- Step 7: Verification queries
-- Check series table
SELECT
    id,
    name,
    difficulty_level,
    word_count,
    supported_languages,
    LEFT(concept, 50) as concept_preview,
    created_at
FROM series
ORDER BY created_at;

-- Check lessons with series
SELECT
    COUNT(*) as total_lessons,
    COUNT(series_id) as lessons_with_series,
    COUNT(*) - COUNT(series_id) as lessons_without_series
FROM lessons;

-- Check series distribution
SELECT
    s.name as series_name,
    s.difficulty_level,
    COUNT(l.id) as lesson_count,
    array_agg(DISTINCT l.language) as languages_with_lessons
FROM series s
LEFT JOIN lessons l ON s.id = l.series_id
GROUP BY s.id, s.name, s.difficulty_level
ORDER BY lesson_count DESC;

-- Verify indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('series', 'lessons')
    AND indexname LIKE '%series%'
ORDER BY tablename, indexname;
