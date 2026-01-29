# WalkingTalking Content Generator

Automated daily content generator for the WalkingTalking iOS app. This Node.js application runs on Vercel, fetches the latest news from Euronews, summarizes it using Gemini AI, generates audio with Google Cloud TTS, and stores everything in Supabase.

## Features

- **Daily Automation**: Runs automatically every day at 6:00 AM UTC via Vercel Cron Jobs
- **Web Scraping**: Fetches latest news articles from Euronews.com
- **AI Summarization**: Uses Google Gemini AI to create 100-150 word summaries formatted for English learning
- **Audio Generation**: Converts each sentence to high-quality audio using Google Cloud Text-to-Speech
- **Cloud Storage**: Stores lessons and audio files in Supabase database and storage

## Prerequisites

Before you begin, you need:

1. **Vercel Account** (Pro plan required for cron jobs - $20/month)
   - Sign up at [vercel.com](https://vercel.com)

2. **Google Cloud Account** for Text-to-Speech API
   - Create a project at [console.cloud.google.com](https://console.cloud.google.com)
   - Enable Text-to-Speech API
   - Create a service account and download JSON credentials

3. **Google AI Studio Account** for Gemini API
   - Get API key at [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)

4. **Supabase Account**
   - Create a project at [supabase.com](https://supabase.com)

## Setup Instructions

### 1. Clone and Install

```bash
cd WalkingTalking_content
npm install
```

### 2. Configure Supabase Database

Run these SQL commands in your Supabase SQL editor:

```sql
-- Create lessons table
CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  source_url TEXT NOT NULL,
  date DATE NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sentences table
CREATE TABLE sentences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  text TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_sentences_lesson_id ON sentences(lesson_id);
CREATE INDEX idx_lessons_date ON lessons(date);
```

### 3. Create Supabase Storage Bucket

1. Go to Storage in your Supabase dashboard
2. Create a new bucket named `audio-files`
3. Make it **public** so the iOS app can access audio files
4. Set appropriate policies for public read access

### 4. Set Up Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your actual credentials:

```env
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_CLOUD_TTS_CREDENTIALS={"type":"service_account",...}
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
API_SECRET=generate_random_secret_here
CRON_SECRET=generate_random_secret_here
```

**Important**: For `GOOGLE_CLOUD_TTS_CREDENTIALS`, paste the entire JSON content from your Google Cloud service account key file as a single line.

### 5. Local Testing

Test the function locally:

```bash
# Install Vercel CLI if you haven't
npm install -g vercel

# Run locally
npm run dev

# Test the endpoint
curl -X POST http://localhost:3000/api/generate-content \
  -H "x-api-secret: your_api_secret_here"
```

### 6. Deploy to Vercel

```bash
# Login to Vercel
vercel login

# Deploy
npm run deploy
```

### 7. Configure Vercel Environment Variables

After deployment, add environment variables in Vercel dashboard:

1. Go to your project settings
2. Navigate to "Environment Variables"
3. Add all variables from your `.env` file
4. Redeploy if necessary

### 8. Enable Cron Jobs

Vercel Cron Jobs require a **Pro plan** ($20/month):

1. Upgrade to Vercel Pro
2. The cron job is already configured in `vercel.json`
3. It will run daily at 6:00 AM UTC
4. Check logs in Vercel dashboard to verify

## Project Structure

```
WalkingTalking_content/
├── api/
│   └── generate-content.ts       # Main Vercel serverless function
├── src/
│   ├── services/
│   │   ├── scraper.ts            # Euronews web scraping
│   │   ├── gemini.ts             # Gemini AI summarization
│   │   ├── tts.ts                # Google Cloud TTS
│   │   └── supabase.ts           # Database operations
│   ├── types/
│   │   └── index.ts              # TypeScript interfaces
│   └── utils/
│       └── logger.ts             # Logging utility
├── package.json
├── tsconfig.json
├── vercel.json                   # Vercel configuration with cron
├── .env.example                  # Environment variables template
└── README.md
```

## API Endpoints

### POST /api/generate-content

Generates daily content (called automatically by cron or manually).

**Manual Trigger:**
```bash
curl -X POST https://your-app.vercel.app/api/generate-content \
  -H "x-api-secret: your_api_secret"
```

**Response:**
```json
{
  "success": true,
  "lessonId": "uuid-here",
  "sentenceCount": 25,
  "message": "Content generated successfully"
}
```

## How It Works

1. **Cron Trigger**: Vercel cron triggers the function daily at 6:00 AM UTC
2. **Scrape News**: Fetches the latest article from Euronews.com
3. **AI Summary**: Gemini AI summarizes the article to 100-150 words, formatted line by line
4. **Generate Audio**: Google Cloud TTS creates audio for each line
5. **Store Data**: Uploads audio files to Supabase Storage and creates database records
6. **iOS Access**: iOS app fetches lessons from Supabase API

## Monitoring

- **Vercel Logs**: Check function execution logs in Vercel dashboard
- **Supabase Dashboard**: Monitor database records and storage usage
- **Error Handling**: All errors are logged with detailed information

## Cost Estimates

- **Vercel Pro**: $20/month (required for cron jobs)
- **Google Cloud TTS**: ~$4 per 1 million characters (~$0.12 per day for 30k chars)
- **Gemini AI**: Currently free tier available
- **Supabase**: Free tier sufficient initially (500 MB database, 1 GB storage)

**Estimated Monthly Cost**: ~$25/month

## Troubleshooting

### Cron Job Not Running

- Verify you're on Vercel Pro plan
- Check cron configuration in `vercel.json`
- View logs in Vercel dashboard under "Deployments" → "Functions"

### Audio Upload Fails

- Verify Supabase storage bucket `audio-files` exists and is public
- Check SUPABASE_SERVICE_KEY has correct permissions
- Review storage policies in Supabase dashboard

### Gemini API Errors

- Verify GEMINI_API_KEY is valid
- Check API quota limits in Google AI Studio
- Review rate limiting

### Google Cloud TTS Errors

- Verify service account JSON is correctly formatted
- Ensure Text-to-Speech API is enabled in Google Cloud Console
- Check service account has "Text-to-Speech User" role

## Future Enhancements

- Add support for multiple news sources
- Implement pronunciation difficulty analysis
- Add content categorization (business, tech, politics, etc.)
- Create admin dashboard for content management
- Add email notifications on success/failure
- Implement content quality scoring

## License

ISC

## Support

For issues or questions, check the logs in Vercel dashboard or review the Supabase database records.
