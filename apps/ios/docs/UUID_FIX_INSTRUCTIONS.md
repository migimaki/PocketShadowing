# Instructions to Fix Channel UUIDs in Supabase

## Problem
All channels in the database have the same placeholder UUID `00000000-0000-0000-0000-000000000`, and all lessons reference this same placeholder UUID in their `channel_id` field.

## Solution
Run the SQL script to assign unique UUIDs to each channel and update all lesson references.

## Steps to Fix

### Option 1: Using Supabase SQL Editor (Recommended)

1. **Open Supabase Dashboard**
   - Go to your Supabase project: https://supabase.com/dashboard

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New query"

3. **Copy and Paste the Script**
   - Open the file: `fix_channel_uuids_simple.sql`
   - Copy all the content
   - Paste it into the SQL Editor

4. **Run the Script**
   - Click the "Run" button (or press Cmd+Enter)
   - The script will:
     - Assign new unique UUIDs to each channel:
       - English channel: `a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d`
       - Japanese channel: `b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e`
       - French channel: `c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f`
     - Update all lessons to reference the correct channel based on their language

5. **Verify the Results**
   - The script will display verification queries showing:
     - All channels with their new UUIDs
     - Lesson count per channel
   - Check that each channel has the correct number of lessons

### What the Script Does

```sql
-- Updates English channel UUID
UPDATE channels SET id = 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d' WHERE language = 'en';

-- Updates Japanese channel UUID
UPDATE channels SET id = 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e' WHERE language = 'ja';

-- Updates French channel UUID
UPDATE channels SET id = 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f' WHERE language = 'fr';

-- Updates all English lessons to reference English channel
UPDATE lessons SET channel_id = 'a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d' WHERE language = 'en';

-- Updates all Japanese lessons to reference Japanese channel
UPDATE lessons SET channel_id = 'b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e' WHERE language = 'ja';

-- Updates all French lessons to reference French channel
UPDATE lessons SET channel_id = 'c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f' WHERE language = 'fr';
```

## After Running the Script

1. **Refresh your iOS app**
   - Close and reopen the app
   - Or tap the refresh button in the Channels view

2. **Verify in the app**
   - Change learning language in settings
   - Each language should show only its corresponding channel
   - Lessons should be properly associated with their channels

## Expected Result

After running the script:

### Channels Table
| id | name | language |
|----|------|----------|
| a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d | Euro News | en |
| b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e | Euro News | ja |
| c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f | Euro News | fr |

### Lessons Table
- All English lessons will have `channel_id = a1b2c3d4-e5f6-4a5b-8c9d-1e2f3a4b5c6d`
- All Japanese lessons will have `channel_id = b2c3d4e5-f6a7-4b5c-9d0e-2f3a4b5c6d7e`
- All French lessons will have `channel_id = c3d4e5f6-a7b8-4c5d-0e1f-3a4b5c6d7e8f`

## Troubleshooting

If you encounter any errors:

1. **Foreign Key Constraint Errors**
   - Make sure your lessons table has a foreign key relationship to channels
   - The script should handle this automatically

2. **Duplicate Key Errors**
   - If you've already run the script once, it will fail on the second run
   - This is expected and means the UUIDs are already updated

3. **No Rows Updated**
   - Check that your channels have the expected language codes (en, ja, fr)
   - Verify the current state of your database

## Rollback (if needed)

If something goes wrong, you can rollback by setting the UUIDs back to the original placeholders:

```sql
UPDATE channels SET id = '00000000-0000-0000-0000-000000000001' WHERE language = 'en';
UPDATE channels SET id = '00000000-0000-0000-0000-000000000002' WHERE language = 'ja';
UPDATE channels SET id = '00000000-0000-0000-0000-000000000003' WHERE language = 'fr';

UPDATE lessons SET channel_id = '00000000-0000-0000-0000-000000000001' WHERE language = 'en';
UPDATE lessons SET channel_id = '00000000-0000-0000-0000-000000000002' WHERE language = 'ja';
UPDATE lessons SET channel_id = '00000000-0000-0000-0000-000000000003' WHERE language = 'fr';
```
