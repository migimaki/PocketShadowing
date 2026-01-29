# PocketShadowing

A language learning application combining iOS mobile app with automated content generation.

## Project Structure

This is a monorepo containing two main applications:

### 📱 iOS App ([apps/ios](apps/ios))
Native iOS application for language learning through shadowing and repetition techniques.
- **Tech Stack**: SwiftUI, SwiftData, AVFoundation, Speech Recognition
- **Platform**: iOS 17.0+
- **Features**: Audio playback, speech recognition, scoring system, progress tracking
- **See**: [apps/ios/README.md](apps/ios/README.md)

### ⚙️ Content API ([apps/content-api](apps/content-api))
Serverless content generator running on Vercel that creates daily lessons from news articles.
- **Tech Stack**: TypeScript, Vercel Functions, Gemini AI, Google Cloud TTS
- **Platform**: Vercel (with scheduled cron jobs)
- **Features**: Web scraping, AI summarization, audio generation, automated scheduling
- **See**: [apps/content-api/README.md](apps/content-api/README.md)

## Getting Started

### Prerequisites
- **For iOS Development**:
  - macOS with Xcode 16+
  - iOS 17.0+ device or simulator

- **For Content API Development**:
  - Node.js 18+
  - Vercel CLI (`npm install -g vercel`)
  - Google Cloud & Gemini API credentials
  - Supabase project

### Quick Start

**1. Clone the repository**
```bash
git clone git@github.com:YOUR_USERNAME/PocketShadowing.git
cd PocketShadowing
```

**2. Set up iOS app**
```bash
cd apps/ios
open WalkingTalking.xcodeproj
# Build and run in Xcode (Cmd+R)
```

**3. Set up Content API**
```bash
cd apps/content-api
npm install
cp .env.example .env
# Edit .env with your credentials
npm run dev
```

## Architecture

### Data Flow
1. **Content API** generates daily lessons from news articles (Euronews)
2. Content is processed through Gemini AI for summarization and structuring
3. Audio files are generated using Google Cloud Text-to-Speech
4. Lessons are stored in **Supabase** (database + storage)
5. **iOS App** fetches lessons from Supabase and provides interactive learning interface

### Shared Infrastructure
- **Supabase**: Centralized backend
  - Database: lessons, sentences, channels
  - Storage: audio files (.mp3)
  - API: RESTful access from both apps
- **Authentication**: Supabase Auth (planned for future)

## Development

### iOS App Development
```bash
cd apps/ios

# Build via Xcode
open WalkingTalking.xcodeproj

# Or build via command line
xcodebuild build -scheme WalkingTalking \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme WalkingTalking \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Content API Development
```bash
cd apps/content-api

# Install dependencies
npm install

# Run TypeScript compiler check
npx tsc --noEmit

# Test locally
npm run dev

# Test the API endpoint
curl -X POST http://localhost:3000/api/generate-content \
  -H "x-api-secret: YOUR_API_SECRET"
```

## Deployment

### iOS App
- Deployed via App Store Connect
- Manual builds and submissions through Xcode
- Requires Apple Developer Program membership

### Content API
- Automated deployment via Vercel
- Connected to GitHub for continuous deployment
- Cron jobs run at scheduled times:
  - **6:00 AM UTC** - Batch 1
  - **6:15 AM UTC** - Batch 2
  - **6:30 AM UTC** - Batch 3
  - **6:45 AM UTC** - Batch 4

```bash
cd apps/content-api

# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

## Environment Variables

### Content API (.env)
Required environment variables for the Content API:

```bash
# Gemini AI API Key
GEMINI_API_KEY=your_key

# Google Cloud Text-to-Speech Credentials (Service Account JSON)
GOOGLE_CLOUD_TTS_CREDENTIALS={"type":"service_account",...}

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_key

# API Secrets
API_SECRET=generate_random_secret
CRON_SECRET=generate_random_secret
```

See [apps/content-api/.env.example](apps/content-api/.env.example) for a complete template with instructions.

### iOS App
- No `.env` file needed
- Configuration in [apps/ios/WalkingTalking/SupabaseConfig.swift](apps/ios/WalkingTalking/SupabaseConfig.swift)
- Uses public Supabase anonymous key

## Technology Stack

### iOS App
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+)
- **Audio**: AVFoundation (playback, recording, TTS)
- **Speech Recognition**: Speech Framework
- **Backend Client**: Supabase Swift SDK
- **Architecture**: MVVM pattern

### Content API
- **Language**: TypeScript (strict mode)
- **Runtime**: Node.js 18+ (Vercel serverless)
- **AI**: Google Gemini AI
- **TTS**: Google Cloud Text-to-Speech
- **Web Scraping**: Axios + Cheerio
- **Database**: Supabase JavaScript SDK
- **Deployment**: Vercel with cron jobs

## Contributing

1. Create a feature branch from `main`
2. Make changes in the appropriate app directory
3. Test thoroughly
4. Submit a pull request

## Migration History

This monorepo was created on 2026-01-29 by combining two separate repositories:
- **iOS App** (19 commits): `git@github.com:migimaki/WalkingTalking.git`
- **Content API** (10 commits): `git@github.com:migimaki/walkingtalking-content.git`

Old git histories are preserved in `.git.old/` directories within each app.

## License

[Add your license here]

## Links

- **Supabase Dashboard**: [https://app.supabase.com](https://app.supabase.com)
- **Vercel Dashboard**: [https://vercel.com](https://vercel.com)
- **Old iOS Repo**: [https://github.com/migimaki/WalkingTalking](https://github.com/migimaki/WalkingTalking) (archived)
- **Old API Repo**: [https://github.com/migimaki/walkingtalking-content](https://github.com/migimaki/walkingtalking-content) (archived)
