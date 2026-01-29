/**
 * Type definitions for WalkingTalking Content Generator
 */

// News Article from web scraping
export interface NewsArticle {
  title: string;
  content: string;
  url: string;
  publishedDate: Date;
}

// Summarized content with line-by-line breakdown
export interface SummarizedContent {
  title: string;
  summary: string;
  lines: string[];
}

// Audio file with metadata
export interface AudioFile {
  lineIndex: number;
  audioBuffer: Buffer;
  mimeType: string;
  fileName: string;      // e.g., "sentence_0.mp3" for individual files
  voiceUsed?: string;    // Track which voice was used for TTS generation
  duration?: number;     // Actual audio duration in seconds (estimated for now)
  // Deprecated: timestamps not needed for individual sentence files
  startTime?: number;    // Optional: only used for legacy bulk audio model
  endTime?: number;      // Optional: only used for legacy bulk audio model
}

// Language codes
export type LanguageCode = 'en' | 'ja' | 'fr';

// Difficulty levels
export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced';

// Voice information
export interface VoiceInfo {
  languageCode: string;
  ssmlGender: 'MALE' | 'FEMALE';
}

// Voice alternation configuration
export interface VoiceAlternationConfig {
  defaultVoice: string;
  alternateVoice: string | null;
  pattern: 'odd_even' | 'none';
}

// Multi-language content
export interface MultiLanguageContent {
  en: SummarizedContent;
  ja: SummarizedContent;
  fr: SummarizedContent;
}

// Series for content organization
export interface Series {
  id: string;
  name: string;
  concept: string;
  cover_image_url?: string;
  line_count: number;  // Target number of sentences/lines (each line = 1 audio file)
  difficulty_level: DifficultyLevel;
  supported_languages: LanguageCode[];
  ai_generation_prompt?: string;
  // Voice configuration
  enable_voice_alternation?: boolean;
  // Gemini-TTS voice names (language-agnostic, applies to all languages)
  default_voice_name?: string;      // Defaults to 'Charon' if null
  alternate_voice_name?: string;    // Used when enable_voice_alternation is true
  // Gemini-TTS prompts (language-specific for en/ja/fr)
  gemini_tts_prompt_en?: string;      // English default voice prompt
  gemini_tts_prompt_ja?: string;      // Japanese default voice prompt
  gemini_tts_prompt_fr?: string;      // French default voice prompt
  gemini_tts_alt_prompt_en?: string;  // English alternate voice prompt
  gemini_tts_alt_prompt_ja?: string;  // Japanese alternate voice prompt
  gemini_tts_alt_prompt_fr?: string;  // French alternate voice prompt
  // Batch assignment for multi-cron scheduling
  batch_number?: number;
  created_at?: string;
  updated_at?: string;
}

// Supabase lesson record
export interface LessonRecord {
  id?: string;
  title: string;
  source_url: string;
  date: string;
  language: LanguageCode;
  channel_id: string;
  content_group_id?: string;
  audio_url?: string;   // Deprecated: not used in sentence-level audio model (use sentence.audio_url instead)
  created_at?: string;
}

// Supabase sentence record
export interface SentenceRecord {
  id?: string;
  lesson_id: string;
  order_index: number;
  text: string;
  audio_url: string;    // Individual sentence audio URL (required for sentence-level model)
  duration: number;     // Audio duration in seconds
  voice_used?: string;  // Track which voice generated the audio
  // Deprecated: timestamps not needed for individual sentence audio files
  start_time?: number | null;  // Optional: only for legacy bulk audio model (set to null)
  end_time?: number | null;    // Optional: only for legacy bulk audio model (set to null)
}

// Content generation result
export interface GenerationResult {
  success: boolean;
  lessonId?: string;
  sentenceCount?: number;
  error?: string;
  message: string;
}

// Multi-series generation result
export interface SeriesGenerationResult {
  success: boolean;
  results: {
    seriesId: string;
    seriesName: string;
    lessons: {
      [language: string]: {
        lessonId: string;
        sentenceCount: number;
      };
    };
  }[];
  errors?: string[];
  message: string;
}

// Logger levels
export type LogLevel = 'info' | 'warn' | 'error' | 'debug';

// Generation log record
export interface GenerationLogRecord {
  id?: string;
  created_at?: string;
  trigger_type: 'cron' | 'manual' | 'api';
  series_ids: string[];
  status: 'success' | 'partial' | 'failed';
  duration_ms: number;
  results?: any; // JSONB - SeriesGenerationResult['results']
  errors?: string[];
  series_count: number;
  lessons_created: number;
  audio_files_generated: number;
  metadata?: any; // JSONB - additional metadata
}

// Environment variables
export interface EnvVars {
  GEMINI_API_KEY: string;
  GOOGLE_CLOUD_TTS_CREDENTIALS: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_KEY: string;
}
