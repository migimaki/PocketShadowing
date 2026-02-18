-- Migration 020: Remove subtitle column from channels table
-- Date: 2026-02-16
-- Purpose: subtitle was a truncated copy of description (first 100 chars).
--          Both columns contained the same data from series.concept.
--          UI handles truncation via SwiftUI .lineLimit(), so subtitle is redundant.

ALTER TABLE channels DROP COLUMN IF EXISTS subtitle;
