-- Migration: Change word_count to line_count
-- Description: Rename word_count column to line_count for better control over lesson length.
--              Each line represents one sentence/audio file, making it easier to manage.
--              Converts existing word counts to approximate line counts (word_count / 15 ≈ lines).
-- Date: 2025-11-28

-- Add new line_count column
ALTER TABLE series
ADD COLUMN IF NOT EXISTS line_count INTEGER DEFAULT 10;

-- Convert existing word_count values to line_count
-- Assumption: ~15 words per line on average
-- Examples: 150 words → 10 lines, 100 words → 7 lines, 200 words → 13 lines
UPDATE series
SET line_count = GREATEST(ROUND(word_count::NUMERIC / 15), 5)  -- Minimum 5 lines
WHERE word_count IS NOT NULL;

-- Remove old word_count column
ALTER TABLE series
DROP COLUMN IF EXISTS word_count;

-- Add NOT NULL constraint after data migration
ALTER TABLE series
ALTER COLUMN line_count SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN series.line_count IS 'Target number of sentences/lines per lesson. Each line becomes one audio file. Default: 10 lines.';
