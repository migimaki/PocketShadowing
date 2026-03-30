-- Migration: Add archive flag to series
-- Description: Adds is_archived column to pause generation for a series without deleting it
-- Date: 2026-03-30

ALTER TABLE series ADD COLUMN is_archived BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_series_archived ON series(is_archived);

COMMENT ON COLUMN series.is_archived IS 'When true, content generation is skipped for this series. Set to false to resume.';
