# Supabase Integration Setup Guide

## Overview
Your iOS app has been updated to fetch lessons from Supabase instead of using hardcoded sample data. The app now supports:
- ✅ Channel-based navigation (Euro News)
- ✅ Fetching lessons from Supabase
- ✅ Audio playback from Supabase Storage (replacing TTS)
- ✅ Offline caching of audio files
- ✅ Date-based lesson display

## Setup Steps

### 1. Add Supabase Swift SDK

1. Open `WalkingTalking.xcodeproj` in Xcode
2. Select your project in the navigator
3. Select the `WalkingTalking` target
4. Go to the "Package Dependencies" tab
5. Click the "+" button at the bottom
6. Enter this URL: `https://github.com/supabase/supabase-swift`
7. Click "Add Package"
8. Select all Supabase products:
   - Supabase
   - Auth
   - Functions
   - PostgREST
   - Realtime
   - Storage
9. Click "Add Package"

### 2. Configure Supabase Credentials

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Navigate to: **Settings** → **API**
4. Copy:
   - **Project URL** (looks like: `https://xxx.supabase.co`)
   - **anon/public** key (NOT the service_role key!)

5. Open `SupabaseConfig.swift` in Xcode
6. Replace the placeholder values:

```swift
struct SupabaseConfig {
    static let supabaseURL = "https://your-project.supabase.co"  // ← Paste your Project URL here
    static let supabaseAnonKey = "eyJhbGc..."                     // ← Paste your anon key here
}
```

⚠️ **Important**: Use the **anon/public** key, NOT the service_role key!

### 3. Add New Files to Xcode Project

All the Swift files have been created, but you need to add them to your Xcode project:

1. In Xcode, right-click on the project navigator
2. Select "Add Files to WalkingTalking..."
3. Navigate to the `WalkingTalking/WalkingTalking/` directory
4. Select these new files (hold Cmd to select multiple):
   - `Channel.swift`
   - `SupabaseConfig.swift`
   - `SupabaseClient.swift`
   - `SupabaseModels.swift`
   - `LessonRepository.swift`
   - `AudioCacheService.swift`
   - `AudioPlayerService.swift`
   - `ChannelListView.swift`
   - `LessonListView.swift`
5. Make sure "Copy items if needed" is **unchecked** (files are already in the right place)
6. Click "Add"

### 4. Build and Run

1. Select your target device or simulator
2. Press Cmd+B to build
3. Fix any compilation errors (should be none if SDK is installed)
4. Press Cmd+R to run

## New Navigation Flow

```
ChannelListView (Root)
  └─ Shows: "Euro News" channel
      └─ LessonListView
          └─ Shows: Lessons with title + date
              └─ PlayerView
                  └─ Plays audio from Supabase Storage
```

## How to Use

1. **Launch the app** - You'll see the Channels screen
2. **Tap "Euro News"** - Navigate to the lesson list
3. **Pull to refresh** - Fetch latest lessons from Supabase
4. **Tap a lesson** - Open the player view
5. **Play** - Audio will download from Supabase (cached locally after first download)

## Features

### Channel List Screen
- Shows all available channels (currently only "Euro News")
- Displays lesson count per channel
- Auto-initializes default channel on first launch

### Lesson List Screen
- Displays lessons sorted by date (newest first)
- Shows:
  - Article title from Euronews
  - Publication date
  - Number of sentences
  - Estimated duration
  - Progress indicator
- Pull-to-refresh to fetch new lessons
- Tap refresh button in toolbar

### Player Screen
- Downloads and caches audio files from Supabase Storage
- Plays real audio instead of TTS
- Shows loading indicator while downloading
- Same shadowing practice flow as before
- Cached files persist across app launches

## Data Flow

```
Supabase Database
  ↓ (fetch via LessonRepository)
SwiftData (local cache)
  ↓
Views (ChannelList → LessonList → Player)
```

```
Supabase Storage (audio-files bucket)
  ↓ (download via AudioCacheService)
Local Documents/AudioCache/
  ↓
AVAudioPlayer (playback)
```

## Troubleshooting

### Build Errors

**Error: "No such module 'Supabase'"**
- Solution: Make sure you added the Supabase Swift SDK (Step 1)
- Try: Product → Clean Build Folder (Cmd+Shift+K)

**Error: "Cannot find 'Channel' in scope"**
- Solution: Make sure all new Swift files are added to the Xcode project (Step 3)

### Runtime Errors

**"Failed to fetch lessons"**
- Check: Are `supabaseURL` and `supabaseAnonKey` set correctly in `SupabaseConfig.swift`?
- Check: Is your Supabase database accessible?
- Check: Are Row Level Security policies set correctly?

**"Failed to load audio"**
- Check: Do sentences have valid `audio_url` values?
- Check: Is the `audio-files` bucket public in Supabase?
- Check: Are audio files uploaded to Supabase Storage?

**Empty lesson list**
- Pull down to refresh
- Or tap the refresh button in the toolbar
- Check Supabase database has lesson data

### Network Issues

- Make sure you're connected to the internet
- Check Supabase project status: https://status.supabase.com

## Database Schema Expected

The app expects this database structure:

### lessons table
- `id` (uuid, primary key)
- `title` (text) - Article title
- `source_url` (text) - Original article URL
- `date` (date) - Publication date (YYYY-MM-DD)
- `created_at` (timestamp)

### sentences table
- `id` (uuid, primary key)
- `lesson_id` (uuid, foreign key → lessons.id)
- `order_index` (integer) - Sentence order (0, 1, 2...)
- `text` (text) - Sentence content
- `audio_url` (text) - Public URL to audio file in Storage
- `duration` (integer) - Duration in seconds
- `created_at` (timestamp)

### audio-files bucket (Supabase Storage)
- Must be set to **public** access
- Audio files organized by date: `YYYY-MM-DD/sentence_0.mp3`

## Security Notes

⚠️ **Never commit real API keys to git!**

For production apps, consider:
1. Using Xcode configuration files (.xcconfig)
2. Environment variables
3. Secure keychain storage
4. Or a secure configuration service

## Next Steps

After everything is working:
- [ ] Test with real Euronews content from your backend
- [ ] Verify audio playback quality
- [ ] Test offline mode (cached audio)
- [ ] Add more channels in the future
- [ ] Consider adding pull-to-refresh indicators
- [ ] Add network error handling UI

## Support

If you encounter issues:
1. Check Xcode console for error messages
2. Verify Supabase credentials in `SupabaseConfig.swift`
3. Test the Supabase API manually using the debug endpoint
4. Check that RLS policies allow reading from `lessons` and `sentences` tables

---

✅ **Your app is now ready to fetch content from Supabase!**
