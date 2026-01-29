# View Mode Toggle Implementation Summary

## ✅ Implementation Complete!

The view mode toggle feature has been successfully implemented. Users can now switch between three viewing modes while practicing:

### 📝 Three View Modes:

1. **Original Mode** (📝)
   - Shows the original sentence text in the learning language
   - Shows recognized speech with color-coded comparison

2. **Translation Mode** (🌐)
   - Shows translation in the user's native language
   - Shows recognized speech with color-coded comparison
   - Automatically loads from linked lessons in the database

3. **Shadowing Mode** (👤)
   - Completely empty view to focus on speaking
   - No text displayed, pure listening practice

### 🎯 Toggle Button Location:
- Left side of the bottom control area
- Cycles through modes: Original → Translation → Shadowing → Original
- Shows current mode with icon and label

## 📋 What Was Changed:

### Database Schema:
- **lessons table**: Added `content_group_id` column (UUID)
  - Links lessons with the same content across different languages

### Code Changes:

1. **SupabaseModels.swift**
   - Added `content_group_id` to LessonDTO

2. **Lesson.swift**
   - Added `contentGroupId` property

3. **LessonRepository.swift**
   - Added `fetchRelatedLessons(for:)` method
   - Added `fetchTranslationSentences(contentGroupId:targetLanguage:)` method
   - Updated `saveLessonsToSwiftData` to save content_group_id

4. **PlayerViewModel.swift**
   - Added `ViewMode` enum (original, translation, shadowing)
   - Added `viewMode` property
   - Added `translationSentences` array
   - Added `toggleViewMode()` method
   - Added `loadTranslationSentences()` method (auto-loads on setup)

5. **ViewModeToggleButton.swift** (NEW)
   - Custom button component showing mode icon and label
   - Changes icon based on current mode

6. **SentencesScrollView.swift**
   - Updated to accept `viewMode` and `translationSentences` parameters
   - Displays content based on current mode
   - Empty view in shadowing mode

7. **PlayerView.swift**
   - Integrated ViewModeToggleButton in bottom controls
   - Passes viewMode and translationSentences to SentencesScrollView
   - Layout: Toggle button (left) | Player controls (center) | Spacer (right)

## 🚀 Next Steps:

### 1. Run SQL Migration

You need to run the database migration to add the `content_group_id` field:

```bash
# Open the file: add_content_group_id_migration.sql
# Copy the SQL content and run it in Supabase SQL Editor
```

The migration will:
- Add `content_group_id` column to the lessons table
- Create an index for faster queries
- **Automatically group existing lessons by date** (lessons on the same date are assumed to be translations)
- Generate a UUID for each group

⚠️ **Important**: The migration groups lessons by `date`. If your lessons use a different method to link translations, you may need to adjust the SQL script.

### 2. Update Future Lesson Creation

When creating new lessons in the future (via your Node.js backend):

```javascript
// 1. Generate a new content_group_id for the English lesson
const contentGroupId = uuidv4();

// 2. Use the SAME content_group_id for all language translations
const englishLesson = {
  id: uuidv4(),
  title: "Lesson Title",
  language: "en",
  content_group_id: contentGroupId,  // <-- Same ID
  // ...other fields
};

const japaneseLesson = {
  id: uuidv4(),
  title: "レッスンタイトル",
  language: "ja",
  content_group_id: contentGroupId,  // <-- Same ID
  // ...other fields
};

const frenchLesson = {
  id: uuidv4(),
  title: "Titre de la leçon",
  language: "fr",
  content_group_id: contentGroupId,  // <-- Same ID
  // ...other fields
};
```

### 3. Test the Feature

After running the migration:

1. Open the app and navigate to a lesson
2. Ensure your native language is set in Settings (different from learning language)
3. Tap the toggle button on the left side of the controls
4. Verify the view cycles through:
   - 📝 Original text
   - 🌐 Translation text (if available)
   - 👤 Empty view (shadowing mode)

### 4. Verify Translation Loading

Check the Xcode console for these messages:
- `[PlayerViewModel] Loaded X translation sentences in [language]` - Success
- `[PlayerViewModel] No content_group_id, translations not available` - No linking
- `[PlayerViewModel] Failed to load translations: ...` - Error fetching

## 🎨 UI Design:

```
┌─────────────────────────────────────┐
│         Lesson Title                │
├─────────────────────────────────────┤
│                                     │
│   [Sentence text or translation]    │
│   [Recognized speech comparison]    │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  📝      ⏮️  ⏯️  ⏭️       [space]   │
│ Original                            │
└─────────────────────────────────────┘
```

Toggle cycles:
- 📝 Original → 🌐 Translation → 👤 Shadow → 📝 Original

## 📊 How Translation Loading Works:

1. When PlayerView opens, PlayerViewModel.setup() is called
2. If lesson has a `contentGroupId`:
   - Fetches related lesson in user's native language from Supabase
   - Extracts sentence texts in correct order
   - Stores in `translationSentences` array
3. If no `contentGroupId` or native language == learning language:
   - Translation mode is skipped when toggling
4. SentencesScrollView displays appropriate text based on mode

## 🔧 Troubleshooting:

### Translation mode not showing:
- Check that lessons have matching `content_group_id` in database
- Verify native language ≠ learning language in Settings
- Check console for error messages

### Empty translation mode:
- Ensure related lesson exists in target language
- Check sentence count matches (same number of sentences)
- Verify sentences are properly ordered (order_index)

### Toggle button not appearing:
- Clean and rebuild project
- Check that ViewModeToggleButton.swift is added to target

## 📁 Files Created/Modified:

### New Files:
- `ViewModeToggleButton.swift`
- `add_content_group_id_migration.sql`
- `VIEW_MODE_IMPLEMENTATION_SUMMARY.md` (this file)

### Modified Files:
- `SupabaseModels.swift`
- `Lesson.swift`
- `LessonRepository.swift`
- `PlayerViewModel.swift`
- `SentencesScrollView.swift`
- `PlayerView.swift`

## ✨ Future Enhancements:

Potential improvements for later:
- Add visual indicator showing which translations are available
- Allow manual refresh of translations
- Cache translations locally for offline use
- Add animation when switching modes
- Show loading indicator while fetching translations
- Add haptic feedback when toggling modes
