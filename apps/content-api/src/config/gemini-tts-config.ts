/**
 * Gemini-TTS Configuration
 * Voice mappings, prompt templates, and speaker catalog
 * English-only TTS (translations are text-only, no audio)
 */

import type { DifficultyLevel } from '../types/index';

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
 * Default speaker for English TTS
 */
export const DEFAULT_SPEAKER: GeminiVoiceName = 'Charon';

/**
 * English language code for Gemini-TTS
 */
export const LANGUAGE_CODE = 'en-US';

/**
 * Default prompt templates by difficulty level
 */
export const DEFAULT_PROMPTS_BY_DIFFICULTY: Record<DifficultyLevel, string> = {
  beginner: 'Generate speech in English. Speak slowly and clearly as if teaching a beginner student. Use natural pauses between phrases. Sound warm and encouraging.',
  intermediate: 'Generate speech in English. Speak naturally with normal pacing. Use expressive intonation to make content engaging. Sound conversational but clear.',
  advanced: 'Generate speech in English. Speak naturally and confidently at normal pace. Use sophisticated intonation. Sound professional and authoritative.',
};

/**
 * Voice alternation prompts for conversational content
 */
export const VOICE_ALTERNATION_PROMPTS = {
  defaultVoicePrompt: 'Generate speech in English. Speak as Person A - a friendly narrator explaining concepts naturally.',
  alternateVoicePrompt: 'Generate speech in English. Speak as Person B - an engaging speaker with a slightly different tone to create natural dialogue.',
};

/**
 * Gets the default prompt for a given difficulty level
 */
export function getDefaultPrompt(difficulty?: DifficultyLevel): string {
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
 */
export function isValidGeminiVoice(voiceName: string | undefined | null): voiceName is GeminiVoiceName {
  if (!voiceName) return false;
  return (ALL_VALID_VOICES as readonly string[]).includes(voiceName);
}

/**
 * Gets a valid voice name with fallback to default
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
