# iOS App Setup Instructions

## 📝 Quick Setup (2 Minutes)

This guide shows you how to set up the PocketShadowing iOS app with your Supabase credentials.

---

## Prerequisites

You need your Supabase credentials:
- **Supabase URL**: Get from [Supabase Dashboard → Settings → API](https://app.supabase.com/project/_/settings/api)
- **Supabase Anon Key**: Get from the same page

---

## Step 1: Create the Generated Config File

The app uses a **generated Swift file** to load credentials. You need to create this file manually:

1. **Copy the example file:**
   ```bash
   cd /Users/keisukeyanagisawa/Documents/Project/PocketShadowing/apps/ios/PocketShadowing/Core
   cp SupabaseConfig.generated.swift.example SupabaseConfig.generated.swift
   ```

2. **Edit the file** and replace the placeholder values:
   ```swift
   // SupabaseConfig.generated.swift
   import Foundation

   // These values are used by SupabaseConfig.swift
   let SUPABASE_URL_VALUE = "YOUR_SUPABASE_URL_HERE"
   let SUPABASE_ANON_KEY_VALUE = "YOUR_SUPABASE_ANON_KEY_HERE"
   ```

3. **Add your actual credentials** from the Supabase dashboard

**Important:** This file is gitignored and will never be committed to source control.

---

## Step 2: Add File to Xcode Project

1. **Open the project:**
   ```bash
   cd /Users/keisukeyanagisawa/Documents/Project/PocketShadowing/apps/ios
   open PocketShadowing.xcodeproj
   ```

2. **Add the file to Xcode:**
   - Right-click on the **"PocketShadowing" folder** (yellow folder in left sidebar)
   - Select **"Add Files to 'PocketShadowing'..."**
   - Navigate to `apps/ios/PocketShadowing/Core/`
   - Select **SupabaseConfig.generated.swift**
   - Make sure:
     - ☐ "Copy items if needed" is **UNCHECKED**
     - ☑ "Create groups" is **SELECTED**
     - ☑ Add to targets: **PocketShadowing** is **CHECKED**
   - Click **"Add"**

---

## Step 3: Build and Run

1. Press **⌘B** to build the project
2. If build succeeds, press **⌘R** to run in the simulator

### Expected Results:

✅ **BUILD SUCCEEDED** - Your configuration is working!

❌ **"Cannot find 'SUPABASE_URL_VALUE' in scope"** - The file wasn't added to the Xcode project. Go back to Step 2.

❌ **"SUPABASE_URL not configured"** - You have placeholder values. Update the file with your actual credentials.

---

## 🔐 Security Notes

### ✅ What's Protected:
- `SupabaseConfig.generated.swift` is gitignored
- Your credentials will never be committed to source control
- The file only exists on your local machine

### ⚠️ What to Do If You Accidentally Commit Secrets:
If you ever accidentally commit credentials to git:
1. **Immediately rotate your Supabase keys** in the dashboard
2. See [ROTATE_SUPABASE_KEY.md](ROTATE_SUPABASE_KEY.md) for instructions

---

## 📁 File Structure

```
apps/ios/PocketShadowing/Core/
├── SupabaseConfig.swift                    # Main config (committed to git)
├── SupabaseConfig.generated.swift          # Your credentials (gitignored)
└── SupabaseConfig.generated.swift.example  # Template file (committed to git)
```

**How it works:**
1. `SupabaseConfig.swift` references constants from the generated file
2. `SupabaseConfig.generated.swift` contains your actual credentials
3. Example file shows the format for new developers

---

## 🆘 Troubleshooting

### "SupabaseConfig.generated.swift.example not found"
Create it manually:
```swift
//
//  SupabaseConfig.generated.swift
//  PocketShadowing
//
//  ⚠️ AUTO-GENERATED - DO NOT COMMIT TO GIT
//  Contains sensitive Supabase credentials
//  This file is gitignored for security
//

import Foundation

// These values are used by SupabaseConfig.swift
let SUPABASE_URL_VALUE = "https://YOUR_PROJECT.supabase.co"
let SUPABASE_ANON_KEY_VALUE = "YOUR_ANON_KEY_HERE"
```

### Build succeeds but app crashes immediately
- Check the Xcode console for error messages
- Verify your Supabase URL and key are correct
- Make sure you didn't include quotes in the values

### Xcode shows red errors even after adding the file
- Close and reopen Xcode
- Clean build folder: **Product → Clean Build Folder** (⌘⇧K)
- Rebuild: **⌘B**

---

**Need help? Let me know what error you're seeing and I'll help fix it!**
