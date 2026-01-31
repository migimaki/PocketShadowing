# iOS App Documentation

## 📚 Documentation Index

### Setup & Configuration
- **[MANUAL_SETUP_INSTRUCTIONS.md](MANUAL_SETUP_INSTRUCTIONS.md)** - Step-by-step Xcode configuration for environment variables
- **[ROTATE_SUPABASE_KEY.md](ROTATE_SUPABASE_KEY.md)** - Security guide for rotating Supabase credentials

### Project Documentation
- **[README.md](README.md)** - Main iOS app overview and getting started
- **[CLAUDE.md](CLAUDE.md)** - Claude AI assistance documentation

### Implementation Guides
- **[MULTI_LANGUAGE_IMPLEMENTATION.md](MULTI_LANGUAGE_IMPLEMENTATION.md)** - Multi-language support architecture
- **[VIEW_MODE_IMPLEMENTATION_SUMMARY.md](VIEW_MODE_IMPLEMENTATION_SUMMARY.md)** - View mode feature implementation
- **[UUID_FIX_INSTRUCTIONS.md](UUID_FIX_INSTRUCTIONS.md)** - UUID handling fixes

---

## 🚀 Quick Start

New to the project? Start here:

1. Read [README.md](README.md) for project overview
2. Follow [MANUAL_SETUP_INSTRUCTIONS.md](MANUAL_SETUP_INSTRUCTIONS.md) to configure Xcode
3. Review [ROTATE_SUPABASE_KEY.md](ROTATE_SUPABASE_KEY.md) for security best practices

## 📁 Configuration Files

### In PocketShadowing/ directory:
- `SupabaseConfig.swift` - Main configuration interface (committed to git)
- `SupabaseConfig.generated.swift` - Your actual credentials (gitignored, never commit!)
- `SupabaseConfig.generated.swift.example` - Template for credentials file

### In parent directory (deprecated):
- `Config.example.xcconfig` - Old xcconfig approach (no longer used, kept for reference)

---

**Need help?** Refer to the specific guide above or see the main project documentation.
