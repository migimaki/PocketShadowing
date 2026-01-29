/**
 * Migration 015: Add Timestamp Support for Single-Audio Approach
 *
 * Changes:
 * 1. Add start_time and end_time columns to sentences table
 * 2. Add audio_url column to lessons table (for shared audio file)
 * 3. Add index for efficient timestamp queries
 * 4. Disable voice alternation for all series (single voice approach)
 */

-- Add timestamp columns to sentences table
ALTER TABLE sentences
ADD COLUMN IF NOT EXISTS start_time DECIMAL(10, 3),  -- Start time in seconds (e.g., 2.456)
ADD COLUMN IF NOT EXISTS end_time DECIMAL(10, 3);    -- End time in seconds (e.g., 5.234)

-- Add lesson-level audio URL column (shared by all sentences)
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS audio_url TEXT;

-- Create index for efficient timestamp queries
CREATE INDEX IF NOT EXISTS idx_sentences_lesson_order
ON sentences(lesson_id, order_index);

-- Disable voice alternation for all series (single voice approach)
UPDATE series
SET enable_voice_alternation = false
WHERE enable_voice_alternation = true;

-- Add comment for documentation
COMMENT ON COLUMN sentences.start_time IS 'Start timestamp in seconds for sentence in lesson audio file';
COMMENT ON COLUMN sentences.end_time IS 'End timestamp in seconds for sentence in lesson audio file';
COMMENT ON COLUMN lessons.audio_url IS 'Public URL to lesson audio file (single file containing all sentences)';
