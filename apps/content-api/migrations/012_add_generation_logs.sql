-- Migration: Add generation logs table
-- Description: Stores logs of content generation runs for monitoring and debugging
-- Date: 2024-11-30

-- Create generation_logs table
CREATE TABLE IF NOT EXISTS generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Timestamp
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Request metadata
  trigger_type VARCHAR(20) NOT NULL, -- 'cron', 'manual', 'api'
  series_ids TEXT[], -- Array of series IDs processed

  -- Results
  status VARCHAR(20) NOT NULL, -- 'success', 'partial', 'failed'
  duration_ms INTEGER NOT NULL, -- Total execution time

  -- Success details (stored as JSONB for flexibility)
  results JSONB, -- Array of successful series results
  /*
  Example structure:
  [
    {
      "seriesId": "uuid",
      "seriesName": "What day is it today",
      "lessons": {
        "en": { "lessonId": "uuid", "sentenceCount": 10 },
        "ja": { "lessonId": "uuid", "sentenceCount": 10 },
        "fr": { "lessonId": "uuid", "sentenceCount": 10 }
      }
    }
  ]
  */

  -- Error details (stored as JSONB)
  errors JSONB, -- Array of error messages if any
  /*
  Example structure:
  [
    "Failed to generate content for series abc123: API quota exceeded",
    "Failed to generate content for series def456: Unknown error"
  ]
  */

  -- Statistics
  series_count INTEGER DEFAULT 0, -- Total series processed
  lessons_created INTEGER DEFAULT 0, -- Total lessons created
  audio_files_generated INTEGER DEFAULT 0, -- Total audio files

  -- Additional metadata
  metadata JSONB -- Any additional info (API versions, etc.)
);

-- Create indexes for common queries
CREATE INDEX idx_generation_logs_created_at ON generation_logs(created_at DESC);
CREATE INDEX idx_generation_logs_status ON generation_logs(status);
CREATE INDEX idx_generation_logs_trigger_type ON generation_logs(trigger_type);

-- Add comment
COMMENT ON TABLE generation_logs IS 'Logs of content generation runs with results and errors for monitoring';
