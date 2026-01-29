-- Migration: Add batch assignment for multi-cron scheduling
-- Description: Adds batch_number column to series table to support splitting content generation into multiple cron jobs
-- Date: 2024-11-30

-- Add batch_number column to series table
ALTER TABLE series ADD COLUMN batch_number INT DEFAULT 1;

-- Create index for efficient batch filtering
CREATE INDEX idx_series_batch ON series(batch_number);

-- Add column comment for documentation
COMMENT ON COLUMN series.batch_number IS 'Batch number for multi-cron job scheduling (1-4). Used to split series into groups processed by different cron jobs.';

-- Assign existing series to batches (adjust based on your actual series)
-- Default: All series start in batch 1
-- You can manually reassign series to different batches using:
-- UPDATE series SET batch_number = 2 WHERE name = 'Series Name';

/*
Example batch assignments for 8 series:
UPDATE series SET batch_number = 1 WHERE name IN ('What day is it today', 'Series 2');
UPDATE series SET batch_number = 2 WHERE name IN ('Series 3', 'Series 4');
UPDATE series SET batch_number = 3 WHERE name IN ('Series 5', 'Series 6');
UPDATE series SET batch_number = 4 WHERE name IN ('Series 7', 'Series 8');

Or by ID:
UPDATE series SET batch_number = 1 WHERE id IN ('uuid-1', 'uuid-2');
UPDATE series SET batch_number = 2 WHERE id IN ('uuid-3', 'uuid-4');
UPDATE series SET batch_number = 3 WHERE id IN ('uuid-5', 'uuid-6');
UPDATE series SET batch_number = 4 WHERE id IN ('uuid-7', 'uuid-8');
*/
