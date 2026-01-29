# Database Migrations

This directory contains SQL migration scripts for the WalkingTalking Supabase database.

## Running Migrations

1. Log in to your Supabase dashboard
2. Navigate to the SQL Editor
3. Run each migration file in order (001, 002, etc.)
4. Verify the changes using the verification queries provided in each migration

## Migration Order

### 001_add_multi_language_support.sql
**Purpose**: Adds multi-language support (English, Japanese, French)

**Changes**:
- Creates `channels` table
- Adds `language` column to `lessons` table
- Adds `channel_id` column to `lessons` table
- Updates unique constraints to support multiple languages per date
- Creates indexes for better query performance

**Prerequisites**: None

**Post-Migration Steps**:
1. Migrate audio files in Supabase Storage (see below)
2. Run `002_migrate_audio_urls.sql`

### 002_migrate_audio_urls.sql
**Purpose**: Updates audio URL paths to new multi-language structure

**Changes**:
- Updates all `audio_url` values in `sentences` table
- Old format: `YYYY-MM-DD/line_XXX.mp3`
- New format: `en/euro-news/YYYY-MM-DD/line_XXX.mp3`

**Prerequisites**:
1. `001_add_multi_language_support.sql` completed
2. Audio files migrated in Supabase Storage (see below)

## Audio File Migration (Supabase Storage)

Before running `002_migrate_audio_urls.sql`, you need to migrate audio files in Supabase Storage:

### Option 1: Using Supabase Dashboard (Manual)
1. Go to Supabase Dashboard → Storage → `audio-files` bucket
2. Create folder structure: `en/euro-news/`
3. For each date folder (e.g., `2025-11-14/`):
   - Move files to `en/euro-news/2025-11-14/`
4. Delete old date folders after verification

### Option 2: Using Supabase API (Programmatic)
Create a Node.js script to:
1. List all files in the bucket
2. For each file matching `YYYY-MM-DD/line_XXX.mp3`:
   - Copy to `en/euro-news/YYYY-MM-DD/line_XXX.mp3`
   - Delete original
3. Verify all files were migrated

Example script (not included, needs to be created if needed):
```javascript
// migrate-storage.js
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

async function migrateAudioFiles() {
  // Implementation here
}
```

## Verification

After running all migrations, verify:

1. **Channels table**: Should have 3 channels (EN, JA, FR)
```sql
SELECT * FROM channels ORDER BY language;
```

2. **Lessons table**: Should have `language` and `channel_id` columns
```sql
SELECT id, title, date, language, channel_id FROM lessons LIMIT 5;
```

3. **Audio URLs**: Should use new path format
```sql
SELECT audio_url FROM sentences LIMIT 10;
```

4. **Unique constraint**: Try inserting duplicate (should fail):
```sql
-- This should fail if constraint is working
INSERT INTO lessons (title, source_url, date, language, channel_id)
VALUES ('Test', 'http://test.com', '2025-11-14', 'en', '00000000-0000-0000-0000-000000000001');
```

## Rollback Instructions

Each migration file includes rollback instructions in comments at the bottom.

**IMPORTANT**: Rollback scripts should be run in reverse order (002, then 001).

## Notes

- Always backup your database before running migrations
- Test migrations in a development environment first
- Verify data integrity after each migration
- Keep this README updated with new migrations
