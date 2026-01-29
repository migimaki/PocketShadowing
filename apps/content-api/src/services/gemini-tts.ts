/**
 * Gemini-TTS Service
 * Generates audio files using Google's Gemini-TTS API (gemini-2.5-flash-tts)
 * Sentence-by-sentence generation for accurate audio boundaries
 */

import type { AudioFile, LanguageCode, Series } from '../types/index';
import { Logger } from '../utils/logger';
import { retryWithBackoff } from '../utils/retry';
import { RateLimiter } from '../utils/rate-limiter';
import { getCachedToken } from './gemini-tts-auth';
import {
  getLanguageCode,
  getDefaultPrompt,
  getAlternationPrompts,
  DEFAULT_SPEAKERS,
  getValidVoice,
  enhancePromptWithLanguage,
} from '../config/gemini-tts-config';

const logger = new Logger('GeminiTTS');

/**
 * Gemini-TTS configuration for a specific audio generation request
 * Supports both single-voice and voice alternation modes
 */
interface GeminiTTSConfig {
  speaker: string;
  prompt: string;
  alternateSpeaker?: string;
  alternatePrompt?: string;
  languageCode: string;
  enableAlternation: boolean;  // NEW: flag to enable voice alternation
}

/**
 * Gemini-TTS API request structure
 */
interface GeminiTTSRequest {
  input: {
    text: string;
    prompt: string;
  };
  voice: {
    languageCode: string;
    name: string;
    modelName: string;
  };
  audioConfig: {
    audioEncoding: string;
  };
}

/**
 * Gemini-TTS API response structure
 */
interface GeminiTTSResponse {
  audioContent: string; // Base64-encoded audio data (camelCase!)
  audioConfig?: {
    audioEncoding: string;
  };
}

/**
 * Get Gemini-TTS configuration from series settings
 * Supports both single-voice and voice alternation modes
 *
 * @param language - Language code (en, ja, fr)
 * @param series - Optional series configuration
 * @returns TTS configuration with voice and prompt settings
 */
function getGeminiTTSConfig(
  language: LanguageCode,
  series?: Series
): GeminiTTSConfig {
  const languageCode = getLanguageCode(language);

  // Determine default voice from series or use fallback
  const defaultVoice = getValidVoice(
    series?.default_voice_name,
    DEFAULT_SPEAKERS[language] // Falls back to 'Charon'
  );

  // Determine if alternation is enabled
  const enableAlternation = series?.enable_voice_alternation === true;

  // Get default prompt (language-specific)
  let defaultPrompt: string;
  const defaultPromptKey = `gemini_tts_prompt_${language}` as keyof Series;
  const seriesDefaultPrompt = series?.[defaultPromptKey] as string | undefined;

  if (seriesDefaultPrompt) {
    defaultPrompt = enhancePromptWithLanguage(seriesDefaultPrompt, language);
  } else {
    const basePrompt = getDefaultPrompt(series?.difficulty_level);
    defaultPrompt = enhancePromptWithLanguage(basePrompt, language);
  }

  // Handle voice alternation if enabled
  let alternateVoice: string | undefined;
  let alternatePrompt: string | undefined;

  if (enableAlternation) {
    // Get alternate voice (with fallback to Kore if not specified)
    alternateVoice = getValidVoice(
      series?.alternate_voice_name,
      'Kore' // Default alternate voice
    );

    // Get alternate prompt (language-specific)
    const altPromptKey = `gemini_tts_alt_prompt_${language}` as keyof Series;
    const seriesAltPrompt = series?.[altPromptKey] as string | undefined;

    if (seriesAltPrompt) {
      alternatePrompt = enhancePromptWithLanguage(seriesAltPrompt, language);
    } else {
      // Use default alternation prompts
      const { defaultVoicePrompt, alternateVoicePrompt } = getAlternationPrompts();
      defaultPrompt = enhancePromptWithLanguage(defaultVoicePrompt, language);
      alternatePrompt = enhancePromptWithLanguage(alternateVoicePrompt, language);
    }
  }

  return {
    speaker: defaultVoice,
    prompt: defaultPrompt,
    alternateSpeaker: alternateVoice,
    alternatePrompt: alternatePrompt,
    languageCode,
    enableAlternation,
  };
}

/**
 * Call Gemini-TTS API to synthesize speech
 */
async function synthesizeSpeech(
  text: string,
  speaker: string,
  prompt: string,
  languageCode: string,
  contextLines?: { allLines: string[]; currentIndex: number }
): Promise<Buffer> {
  const accessToken = await getCachedToken();

  // Enhance prompt with context if provided
  let enhancedPrompt = prompt;
  if (contextLines) {
    const { allLines, currentIndex } = contextLines;
    const fullText = allLines.join(' ');

    enhancedPrompt = `CONTEXT: This is line ${currentIndex + 1} of ${allLines.length} in a continuous narrative. The full story is: "${fullText}"

You are now speaking line ${currentIndex + 1}: "${text}"

Consider the flow and tone of the entire narrative. Match your emotion and pacing to fit naturally within this story. Don't over-dramatize this individual line - it should feel like a natural part of the complete narrative.

${prompt}`;
  }

  const request: GeminiTTSRequest = {
    input: {
      text,
      prompt: enhancedPrompt,
    },
    voice: {
      languageCode,
      name: speaker,
      modelName: 'gemini-2.5-flash-tts',
    },
    audioConfig: {
      audioEncoding: 'MP3',
    },
  };

  logger.debug('Calling Gemini-TTS API', {
    textLength: text.length,
    speaker,
    promptLength: enhancedPrompt.length,
    hasContext: !!contextLines,
    languageCode,
    model: 'gemini-2.5-flash-tts',
  });

  const response = await fetch('https://texttospeech.googleapis.com/v1/text:synthesize', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini-TTS API error: ${response.status} ${errorText}`);
  }

  const data = await response.json() as GeminiTTSResponse;

  // Log the response structure for debugging
  logger.debug('Gemini-TTS API response', {
    hasAudioContent: !!data.audioContent,
    hasAudioConfig: !!data.audioConfig,
    responseKeys: Object.keys(data),
  });

  if (!data.audioContent) {
    logger.error('No audioContent in response', {
      responseData: JSON.stringify(data).substring(0, 500),
    });
    throw new Error('No audio content returned from Gemini-TTS API');
  }

  // Decode base64 audio content
  const audioBuffer = Buffer.from(data.audioContent, 'base64');

  logger.debug('Successfully synthesized speech', {
    audioSizeBytes: audioBuffer.length,
  });

  return audioBuffer;
}

/**
 * Generates audio for a SINGLE sentence using Gemini-TTS
 * Returns audio buffer, estimated duration, and voice used
 *
 * @param text - Text to synthesize
 * @param speaker - Voice name to use
 * @param prompt - Voice prompt/instruction
 * @param languageCode - BCP-47 language code
 * @param sentenceIndex - Index of sentence (for logging)
 * @param totalSentences - Total number of sentences (for logging)
 * @returns Audio buffer, duration, and voice name used
 */
async function generateSentenceAudio(
  text: string,
  speaker: string,
  prompt: string,
  languageCode: string,
  sentenceIndex: number,
  totalSentences: number
): Promise<{ audioBuffer: Buffer; duration: number; voiceUsed: string }> {
  logger.info(`Generating audio for sentence ${sentenceIndex + 1}/${totalSentences}`, {
    textPreview: text.substring(0, 60) + (text.length > 60 ? '...' : ''),
    textLength: text.length,
    speaker
  });

  const audioBuffer = await retryWithBackoff(
    async () => synthesizeSpeech(text, speaker, prompt, languageCode, undefined),
    `Gemini-TTS sentence ${sentenceIndex + 1}/${totalSentences}`,
    3, // maxRetries
    1000 // baseDelay (1 second)
  );

  // Estimate duration for metadata (used for display purposes only)
  const duration = estimateAudioDuration(text);

  logger.debug(`Sentence ${sentenceIndex + 1} audio generated`, {
    sizeBytes: audioBuffer.length,
    estimatedDuration: duration,
    voiceUsed: speaker
  });

  return {
    audioBuffer,
    duration,
    voiceUsed: speaker
  };
}

/**
 * Generates INDIVIDUAL audio files for each sentence using Gemini-TTS
 * Supports voice alternation when enabled in series configuration
 * Rate limiting: 10 req/min (6+ seconds between calls)
 *
 * @param lines - Array of text lines to convert to speech
 * @param language - Language code (en, ja, or fr)
 * @param series - Optional series object with custom prompts and voice configuration
 */
export async function generateAudioFiles(
  lines: string[],
  language: LanguageCode = 'en',
  series?: Series
): Promise<AudioFile[]> {
  try {
    logger.info(`Generating ${lines.length} individual audio files in ${language.toUpperCase()}`, {
      seriesId: series?.id,
      seriesName: series?.name,
      voiceAlternationEnabled: series?.enable_voice_alternation || false,
    });

    const config = getGeminiTTSConfig(language, series);

    // Log voice configuration
    logger.info('Voice configuration', {
      defaultVoice: config.speaker,
      alternateVoice: config.alternateSpeaker,
      alternationEnabled: config.enableAlternation,
      hasCustomPrompts: !!(
        series?.gemini_tts_prompt_en || series?.gemini_tts_prompt_ja || series?.gemini_tts_prompt_fr ||
        series?.gemini_tts_alt_prompt_en || series?.gemini_tts_alt_prompt_ja || series?.gemini_tts_alt_prompt_fr
      ),
    });

    // Initialize rate limiter: 10 req/min with 1 second safety buffer
    const rateLimiter = new RateLimiter(10, 1000);
    const audioFiles: AudioFile[] = [];

    // Calculate estimated time
    const estimatedTimeSeconds = lines.length * 7; // 7 seconds per call (6s min + 1s buffer)
    const estimatedTimeMinutes = Math.ceil(estimatedTimeSeconds / 60);

    logger.info('Starting sentence-by-sentence audio generation', {
      sentenceCount: lines.length,
      defaultVoice: config.speaker,
      alternateVoice: config.alternateSpeaker || 'none',
      estimatedTimeMinutes: estimatedTimeMinutes,
      rateLimit: '10 req/min (7s between calls)'
    });

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // VOICE ALTERNATION LOGIC
      // Odd-numbered indices (0, 2, 4...) use default voice
      // Even-numbered indices (1, 3, 5...) use alternate voice (if enabled)
      const isAlternateSentence = i % 2 === 1;
      const useAlternateVoice = config.enableAlternation && isAlternateSentence;

      const selectedVoice = useAlternateVoice && config.alternateSpeaker
        ? config.alternateSpeaker
        : config.speaker;

      const selectedPrompt = useAlternateVoice && config.alternatePrompt
        ? config.alternatePrompt
        : config.prompt;

      logger.debug(`Sentence ${i}: voice selection`, {
        index: i,
        pattern: i % 2 === 0 ? 'odd (default)' : 'even (alternate)',
        alternationEnabled: config.enableAlternation,
        selectedVoice,
      });

      // Rate limiting: wait before each API call (except first)
      if (i > 0) {
        await rateLimiter.waitIfNeeded();
      }

      // Generate audio for this sentence
      const { audioBuffer, duration, voiceUsed } = await generateSentenceAudio(
        line,
        selectedVoice,
        selectedPrompt,
        config.languageCode,
        i,
        lines.length
      );

      audioFiles.push({
        lineIndex: i,
        audioBuffer,
        mimeType: 'audio/mpeg',
        fileName: `sentence_${i}.mp3`,
        voiceUsed: voiceUsed,
        duration: duration,
        // No startTime/endTime needed for individual files
      });

      logger.info(`✓ Sentence ${i + 1}/${lines.length} completed`, {
        fileName: `sentence_${i}.mp3`,
        voice: voiceUsed,
        sizeKB: (audioBuffer.length / 1024).toFixed(1),
        duration: `${duration}s`
      });
    }

    // Log summary with voice usage statistics
    const voiceUsageStats: Record<string, number> = {};
    audioFiles.forEach(f => {
      if (f.voiceUsed) {
        voiceUsageStats[f.voiceUsed] = (voiceUsageStats[f.voiceUsed] || 0) + 1;
      }
    });

    logger.info('All sentence audio files generated successfully', {
      totalFiles: audioFiles.length,
      voiceUsageStats,
      totalSizeKB: (audioFiles.reduce((sum, f) => sum + f.audioBuffer.length, 0) / 1024).toFixed(1)
    });

    return audioFiles;

  } catch (error) {
    logger.error('Error generating sentence audio files', error);
    throw new Error(`Failed to generate audio: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Estimates the duration of audio in seconds based on text length
 * Rough estimation: ~150 words per minute = 2.5 words per second
 */
export function estimateAudioDuration(text: string): number {
  const wordCount = text.split(/\s+/).length;
  const wordsPerSecond = 2.5;
  const duration = Math.ceil(wordCount / wordsPerSecond);
  return Math.max(duration, 1); // Minimum 1 second
}
