# Manual Xcode Configuration Instructions

## 📝 5-Minute Setup (Recommended Approach)

These manual steps are the safest and most reliable way to configure your project.

---

## Step 1: Open Project in Xcode

```bash
cd /Users/keisukeyanagisawa/Documents/Project/PocketShadowing/apps/ios
open PocketShadowing.xcodeproj
```

---

## Step 2: Add Config.xcconfig to Project

1. In Xcode's left sidebar (Project Navigator), **right-click** on the blue "PocketShadowing" project icon at the very top
2. Select **"Add Files to 'PocketShadowing'..."**
3. Navigate to and select **`Config.xcconfig`** (it's in the `ios/` directory)
4. **IMPORTANT:** Uncheck ☐ "Copy items if needed"
5. **IMPORTANT:** Under "Add to targets", uncheck ALL targets
6. Click **"Add"**

You should now see `Config.xcconfig` in the project navigator.

---

## Step 3: Link Config.xcconfig to Build Configurations

1. Click the **blue "PocketShadowing" project icon** at the top of the navigator
2. Make sure you're on the **PROJECT** (not the target) - you'll see "PocketShadowing" with "1 target" underneath
3. Select the **"Info" tab** (in the main editor area)
4. Scroll down to **"Configurations"**
5. Expand **"Debug"**:
   - Click the dropdown next to "PocketShadowing" target
   - Select **"Config"**
6. Expand **"Release"**:
   - Click the dropdown next to "PocketShadowing" target
   - Select **"Config"**

You should now see "Config" selected for both Debug and Release configurations.

---

## Step 4: Build the Project

1. Press **⌘B** (or select **Product → Build** from the menu)
2. Wait for the build to complete

### Expected Results:

✅ **BUILD SUCCEEDED** - Your configuration is working! Proceed to Step 5.

❌ **BUILD FAILED** with "Provisioning profile" error - This is OK! It's just a code signing issue, not related to our config. Proceed to Step 5.

❌ **BUILD FAILED** with "SUPABASE_URL not found" - The Config.xcconfig isn't linked properly. Go back to Step 3.

---

## Step 5: Verify Configuration

Run a quick test to see if the config is loaded:

1. Open **`SupabaseConfig.swift`** in Xcode
2. Add a temporary print statement:
   ```swift
   static let supabaseURL: String = {
       guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
             !url.isEmpty,
             !url.contains("$") else {
           fatalError("SUPABASE_URL not configured...")
       }
       print("✅ Loaded Supabase URL: \(url)") // ADD THIS LINE
       return url
   }()
   ```
3. Build and run in the simulator
4. Check the console output for "✅ Loaded Supabase URL:"

---

## ✅ Configuration Complete!

Once you've successfully built the project, you're ready for the **critical next step**:

### 🔐 **ROTATE YOUR SUPABASE KEY IMMEDIATELY**

See **`ROTATE_SUPABASE_KEY.md`** for detailed instructions.

**Why this is critical:**
- Your old key was committed to git history
- Anyone with repo access can see it
- The key must be rotated to secure your database

---

## 🆘 Troubleshooting

### "Config.xcconfig not found"
- Make sure you created `Config.xcconfig` (not just `Config.example.xcconfig`)
- Check that it's in the `apps/ios/` directory
- Verify it contains your actual Supabase credentials

### "Config" doesn't appear in the dropdown
- Make sure you added Config.xcconfig to the project (Step 2)
- Try closing and reopening Xcode
- Make sure you didn't check "Copy items if needed" when adding the file

### Build succeeds but app crashes with "SUPABASE_URL not configured"
- The xcconfig file isn't being applied correctly
- Try **Product → Clean Build Folder** (⌘⇧K)
- Then rebuild (⌘B)

---

**Need help? Let me know what error you're seeing and I'll help fix it!**
