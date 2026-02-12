/**
 * Type definitions for PocketShadowing Content Generator
 */

// Translation languages supported (add new languages here)
export const TRANSLATION_LANGUAGES = ['ja', 'fr'] as const;
export type TranslationLanguage = (typeof TRANSLATION_LANGUAGES)[number];

// Difficulty levels
export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced';

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
}

// Multi-language content (English + translations)
export interface MultiLanguageContent {
  en: SummarizedContent;
  translations: Record<string, SummarizedContent>;
}

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

// Series for content organization
export interface Series {
  id: string;
  name: string;
  concept: string;
  cover_image_url?: string;
  line_count: number;
  difficulty_level: DifficultyLevel;
  ai_generation_prompt?: string;
  // Voice configuration
  enable_voice_alternation?: boolean;
  default_voice_name?: string;
  alternate_voice_name?: string;
  // Gemini-TTS prompts (English only)
  gemini_tts_prompt?: string;
  gemini_tts_alt_prompt?: string;
  // Batch assignment for multi-cron scheduling
  batch_number?: number;
  created_at?: string;
  updated_at?: string;
}

// Supabase lesson record (English only)
export interface LessonRecord {
  id?: string;
  title: string;
  source_url: string;
  date: string;
  channel_id: string;
  audio_url?: string;
  created_at?: string;
}

// Supabase sentence record
export interface SentenceRecord {
  id?: string;
  lesson_id: string;
  order_index: number;
  text: string;
  audio_url: string;
  duration: number;
  voice_used?: string;
  start_time?: number | null;
  end_time?: number | null;
}

// Translation records for the new translation tables
export interface LessonTranslationRecord {
  id?: string;
  lesson_id: string;
  language: string;
  title: string;
  created_at?: string;
}

export interface SentenceTranslationRecord {
  id?: string;
  sentence_id: string;
  language: string;
  text: string;
  created_at?: string;
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
    lessonId: string;
    sentenceCount: number;
    translationLanguages: string[];
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
  results?: any;
  errors?: string[];
  series_count: number;
  lessons_created: number;
  audio_files_generated: number;
  metadata?: any;
}

// Environment variables
export interface EnvVars {
  GEMINI_API_KEY: string;
  GOOGLE_CLOUD_TTS_CREDENTIALS: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_KEY: string;
}
