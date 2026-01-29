/**
 * Gemini-TTS Configuration
 * Voice mappings, prompt templates, and speaker catalog
 */

import type { LanguageCode, DifficultyLevel } from '../types/index';

/**
 * Valid Gemini-TTS voice names
 * Total: 30 voices (14 female, 16 male)
 * Source: Google Gemini-TTS API documentation
 */
export const VALID_GEMINI_VOICES = {
  female: [
    'Achernar', 'Aoede', 'Autonoe', 'Callirrhoe', 'Despina',
    'Erinome', 'Gacrux', 'Kore', 'Laomedeia', 'Leda',
    'Pulcherrima', 'Sulafat', 'Vindemiatrix', 'Zephyr'
  ] as const,
  male: [
    'Achird', 'Algenib', 'Algieba', 'Alnilam', 'Charon',
    'Enceladus', 'Fenrir', 'Iapetus', 'Orus', 'Puck',
    'Rasalgethi', 'Sadachbia', 'Sadaltager', 'Schedar',
    'Umbriel', 'Zubenelgenubi'
  ] as const,
} as const;

/**
 * All valid voice names as a flat array for validation
 */
export const ALL_VALID_VOICES = [
  ...VALID_GEMINI_VOICES.female,
  ...VALID_GEMINI_VOICES.male
] as const;

/**
 * Type for valid Gemini-TTS voice names
 */
export type GeminiVoiceName = typeof ALL_VALID_VOICES[number];

/**
 * Maps Google Cloud Neural2 voices to Gemini-TTS speaker names
 * Valid Gemini TTS voices:
 * Female: Achernar, Aoede, Autonoe, Callirrhoe, Despina, Erinome, Gacrux,
 *         Kore, Laomedeia, Leda, Pulcherrima, Sulafat, Vindemiatrix, Zephyr
 * Male: Achird, Algenib, Algieba, Alnilam, Charon, Enceladus, Fenrir,
 *       Iapetus, Orus, Puck, Rasalgethi, Sadachbia, Sadaltager, Schedar,
 *       Umbriel, Zubenelgenubi
 */
export const GEMINI_SPEAKER_MAPPING: Record<LanguageCode, Record<string, string>> = {
  en: {
    'en-US-Neural2-J': 'Charon',      // Male, clear, professional
    'en-US-Neural2-F': 'Kore',        // Female, professional
    'en-US-Neural2-D': 'Puck',        // Male, deep
    'en-US-Neural2-H': 'Aoede',       // Female, friendly
  },
  ja: {
    'ja-JP-Neural2-C': 'Charon',      // Male, professional
    'ja-JP-Neural2-B': 'Kore',        // Female voice
    'ja-JP-Neural2-D': 'Puck',        // Deep male voice
    'ja-JP-Wavenet-A': 'Aoede',       // Alternative female
  },
  fr: {
    'fr-FR-Neural2-B': 'Charon',      // Male, clear
    'fr-FR-Neural2-A': 'Kore',        // Female, natural
    'fr-FR-Neural2-D': 'Puck',        // Male, deep
    'fr-FR-Wavenet-C': 'Aoede',       // Female, warm
  },
};

/**
 * Default Gemini-TTS speakers for each language
 */
export const DEFAULT_SPEAKERS: Record<LanguageCode, GeminiVoiceName> = {
  en: 'Charon',  // Male, clear voice
  ja: 'Charon',  // Male, clear voice
  fr: 'Charon',  // Male, clear voice
};

/**
 * Default prompt templates by difficulty level
 * English prompts work for all languages in Gemini-TTS
 */
export const DEFAULT_PROMPTS_BY_DIFFICULTY: Record<DifficultyLevel, string> = {
  beginner: 'Speak slowly and clearly as if teaching a beginner student. Use natural pauses between phrases. Sound warm and encouraging.',
  intermediate: 'Speak naturally with normal pacing. Use expressive intonation to make content engaging. Sound conversational but clear.',
  advanced: 'Speak naturally and confidently at normal pace. Use sophisticated intonation. Sound professional and authoritative.',
};

/**
 * Voice alternation prompts for conversational content
 * Used when series have voice alternation enabled
 * English prompts work for all languages in Gemini-TTS
 */
export const VOICE_ALTERNATION_PROMPTS = {
  defaultVoicePrompt: 'Speak as Person A - a friendly narrator explaining concepts naturally.',
  alternateVoicePrompt: 'Speak as Person B - an engaging speaker with a slightly different tone to create natural dialogue.',
};

/**
 * Maps language codes to BCP-47 language codes used by Gemini-TTS
 */
export function getLanguageCode(language: LanguageCode): string {
  const languageCodeMap: Record<LanguageCode, string> = {
    en: 'en-US',
    ja: 'ja-JP',
    fr: 'fr-FR',
  };

  return languageCodeMap[language];
}

/**
 * Maps language codes to full language names for explicit TTS instructions
 */
export function getLanguageName(language: LanguageCode): string {
  const languageNames: Record<LanguageCode, string> = {
    en: 'English',
    ja: 'Japanese',
    fr: 'French',
  };
  return languageNames[language];
}

/**
 * Enhances a prompt with explicit language specification
 * Ensures Gemini TTS generates audio in the correct language
 */
export function enhancePromptWithLanguage(prompt: string, language: LanguageCode): string {
  const languageName = getLanguageName(language);
  return `Generate speech in ${languageName}. ${prompt}`;
}

/**
 * Gets the Gemini-TTS speaker name from a Google Cloud voice name
 * Falls back to default speaker if mapping not found
 */
export function mapVoiceToSpeaker(voiceName: string, language: LanguageCode): string {
  const mapping = GEMINI_SPEAKER_MAPPING[language];
  return mapping[voiceName] || DEFAULT_SPEAKERS[language];
}

/**
 * Gets the default prompt for a given difficulty level
 */
export function getDefaultPrompt(difficulty?: DifficultyLevel): string {
  // Default to intermediate if difficulty not specified
  const level = difficulty || 'intermediate';
  return DEFAULT_PROMPTS_BY_DIFFICULTY[level];
}

/**
 * Gets voice alternation prompts
 */
export function getAlternationPrompts(): {
  defaultVoicePrompt: string;
  alternateVoicePrompt: string;
} {
  return VOICE_ALTERNATION_PROMPTS;
}

/**
 * Validates if a voice name is valid for Gemini-TTS
 * @param voiceName - Voice name to validate
 * @returns true if valid, false otherwise
 */
export function isValidGeminiVoice(voiceName: string | undefined | null): voiceName is GeminiVoiceName {
  if (!voiceName) return false;
  return (ALL_VALID_VOICES as readonly string[]).includes(voiceName);
}

/**
 * Gets a valid voice name with fallback to default
 * @param voiceName - Voice name to validate
 * @param fallback - Fallback voice (defaults to 'Charon')
 * @returns Valid voice name
 */
export function getValidVoice(
  voiceName: string | undefined | null,
  fallback: GeminiVoiceName = 'Charon'
): GeminiVoiceName {
  if (isValidGeminiVoice(voiceName)) {
    return voiceName;
  }
  return fallback;
}
