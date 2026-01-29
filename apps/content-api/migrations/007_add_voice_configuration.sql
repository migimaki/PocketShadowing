-- Migration: Add voice configuration support
-- Date: 2025-11-26
-- Purpose: Enable multi-voice TTS generation with series-level defaults and sentence-level alternation

-- Step 1: Add voice configuration columns to series table
ALTER TABLE series
ADD COLUMN IF NOT EXISTS default_voice_en VARCHAR(100) DEFAULT 'en-US-Neural2-J',
ADD COLUMN IF NOT EXISTS default_voice_ja VARCHAR(100) DEFAULT 'ja-JP-Neural2-C',
ADD COLUMN IF NOT EXISTS default_voice_fr VARCHAR(100) DEFAULT 'fr-FR-Neural2-B',
ADD COLUMN IF NOT EXISTS enable_voice_alternation BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS voice_alternation_pattern VARCHAR(20) DEFAULT 'odd_even'
  CHECK (voice_alternation_pattern IN ('odd_even', 'none'));

-- Step 2: Add secondary voices for alternation
ALTER TABLE series
ADD COLUMN IF NOT EXISTS alternate_voice_en VARCHAR(100),
ADD COLUMN IF NOT EXISTS alternate_voice_ja VARCHAR(100),
ADD COLUMN IF NOT EXISTS alternate_voice_fr VARCHAR(100);

-- Step 3: Add voice_used field to sentences table to track which voice generated each audio
ALTER TABLE sentences
ADD COLUMN IF NOT EXISTS voice_used VARCHAR(100);

-- Step 4: Create index for voice_used queries
CREATE INDEX IF NOT EXISTS idx_sentences_voice_used ON sentences(voice_used);

-- Step 5: Update existing "Euro News Daily" series with explicit defaults
UPDATE series
SET
  default_voice_en = 'en-US-Neural2-J',
  default_voice_ja = 'ja-JP-Neural2-C',
  default_voice_fr = 'fr-FR-Neural2-B',
  enable_voice_alternation = false
WHERE name = 'Euro News Daily';

-- Step 6: Create example "Small Talk" series with alternating voices for demonstration
INSERT INTO series (
    name,
    concept,
    word_count,
    difficulty_level,
    supported_languages,
    default_voice_en,
    alternate_voice_en,
    default_voice_ja,
    alternate_voice_ja,
    default_voice_fr,
    alternate_voice_fr,
    enable_voice_alternation,
    voice_alternation_pattern,
    ai_generation_prompt
) VALUES (
    'Small Talk',
    'Everyday casual conversations between two people. Practice natural dialogue with alternating speakers.',
    120,
    'beginner',
    ARRAY['en', 'ja', 'fr']::VARCHAR[],
    'en-US-Neural2-J',  -- Male voice (Person A)
    'en-US-Neural2-F',  -- Female voice (Person B)
    'ja-JP-Neural2-C',  -- Male voice (Person A)
    'ja-JP-Neural2-B',  -- Female voice (Person B)
    'fr-FR-Neural2-B',  -- Male voice (Person A)
    'fr-FR-Neural2-A',  -- Female voice (Person B)
    true,               -- Enable alternation
    'odd_even',
    'Generate natural everyday conversation between two people. Each line should be a short conversational exchange suitable for language learners. Focus on common daily situations like greetings, weather, hobbies, food, and weekend plans.'
) ON CONFLICT DO NOTHING;

-- Verification queries (for manual testing):
-- SELECT name, default_voice_en, alternate_voice_en, enable_voice_alternation FROM series;
-- SELECT id, text, voice_used FROM sentences WHERE lesson_id = 'some-lesson-id' ORDER BY order_index;
