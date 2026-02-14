-- Migration 019: Enable Row Level Security on unprotected tables
--
-- Tables lesson_translations, sentence_translations, and generation_logs
-- are currently UNRESTRICTED. This enables RLS with read-only access
-- for the anon role (iOS app) while service_role (content-api) bypasses
-- RLS automatically.

-- ============================================================
-- lesson_translations
-- ============================================================
ALTER TABLE lesson_translations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access"
  ON lesson_translations
  FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- sentence_translations
-- ============================================================
ALTER TABLE sentence_translations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access"
  ON sentence_translations
  FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- generation_logs
-- ============================================================
ALTER TABLE generation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access"
  ON generation_logs
  FOR SELECT
  TO anon
  USING (true);
