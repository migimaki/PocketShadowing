# 🔐 Supabase Key Rotation Guide

## ⚠️ CRITICAL: Your current Supabase key was committed to git and must be rotated immediately!

### Why Rotate?
The anon key `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` is visible in your git history. Anyone with access to the repository can use it to connect to your Supabase database.

---

## Step-by-Step Rotation Process

### 1. Access Supabase Dashboard
1. Go to https://app.supabase.com
2. Select your project: **tfyanffhqxiasxpbjgna**
3. Navigate to **Project Settings** (gear icon in sidebar)
4. Click **API** in the left menu

### 2. Rotate the Anonymous Key
1. Scroll down to **Project API keys**
2. Find the **anon** / **public** key section
3. Click **"Rotate"** or **"Regenerate"** (button may vary)
4. **IMPORTANT:** Copy the new key immediately - you won't see it again!

### 3. Update Your Configuration
1. Open `apps/ios/PocketShadowing/Core/SupabaseConfig.generated.swift`
2. Replace the old key with the new one:
   ```swift
   let SUPABASE_ANON_KEY_VALUE = "<paste_new_key_here>"
   ```
3. Save the file

### 4. Update Content API (if using the same key)
1. Open `apps/content-api/.env`
2. Update `SUPABASE_SERVICE_KEY` if needed (this is a different key!)
3. Note: The content API uses the **service_role** key, not the **anon** key

### 5. Verify on Vercel (Production)
1. Go to https://vercel.com/dashboard
2. Select your `content-api` project
3. Go to **Settings** → **Environment Variables**
4. Verify `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are set
5. **Do NOT change these** unless you're rotating the service key too

### 6. Test Your Applications

**iOS App:**
```bash
# Build and run
cd apps/ios
open PocketShadowing.xcodeproj
# Press ⌘B to build, ⌘R to run
```

**Content API (Local):**
```bash
cd apps/content-api
npm run dev
# Test: curl http://localhost:3000/api/debug
```

### 7. Verify the Old Key is Revoked
1. Try using the old key in a test
2. It should return a **401 Unauthorized** error
3. If it still works, contact Supabase support

---

## 🔒 Security Best Practices Going Forward

### ✅ DO:
- Keep `SupabaseConfig.generated.swift` in `.gitignore` (already done)
- Use different keys for dev/staging/production
- Rotate keys every 90 days
- Use Row Level Security (RLS) policies in Supabase

### ❌ DON'T:
- Never commit `SupabaseConfig.generated.swift` to git
- Never share keys in Slack/Discord/email
- Never hardcode keys in source files
- Never use the service_role key in client apps

---

## 📋 Checklist

- [ ] Rotated Supabase anon key in dashboard
- [ ] Updated `apps/ios/PocketShadowing/Core/SupabaseConfig.generated.swift` with new key
- [ ] Tested iOS app builds and connects successfully
- [ ] Verified old key no longer works
- [ ] Checked `.gitignore` includes `SupabaseConfig.generated.swift`
- [ ] Committed all changes (except SupabaseConfig.generated.swift)

---

## 🆘 Troubleshooting

### "Invalid API key" error in iOS app
- Check `SupabaseConfig.generated.swift` has the correct new key
- Clean build folder: **Product → Clean Build Folder** (⌘⇧K)
- Rebuild: **Product → Build** (⌘B)

### "Connection refused" error
- Verify `SUPABASE_URL` is correct in `SupabaseConfig.generated.swift`
- Check network connectivity
- Verify Supabase project is not paused

### Key rotation failed
- You may need to regenerate the key from scratch
- Go to **Project Settings → API → Reset Project API Keys**
- This will invalidate ALL existing keys

---

## 📚 Additional Resources
- [Supabase API Keys Documentation](https://supabase.com/docs/guides/api/api-keys)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/going-into-prod#security)
