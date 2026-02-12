/**
 * Gemini-TTS Service
 * Generates English audio files using Google's Gemini-TTS API (gemini-2.5-flash-tts)
 * Sentence-by-sentence generation for accurate audio boundaries
 */

import type { AudioFile, Series } from '../types/index';
import { Logger } from '../utils/logger';
import { retryWithBackoff } from '../utils/retry';
import { RateLimiter } from '../utils/rate-limiter';
import { getCachedToken } from './gemini-tts-auth';
import {
  LANGUAGE_CODE,
  DEFAULT_SPEAKER,
  getDefaultPrompt,
  getAlternationPrompts,
  getValidVoice,
} from '../config/gemini-tts-config';

const logger = new Logger('GeminiTTS');

/**
 * Gemini-TTS configuration for a specific audio generation request
 */
interface GeminiTTSConfig {
  speaker: string;
  prompt: string;
  alternateSpeaker?: string;
  alternatePrompt?: string;
  enableAlternation: boolean;
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
  audioContent: string;
  audioConfig?: {
    audioEncoding: string;
  };
}

/**
 * Get Gemini-TTS configuration from series settings (English only)
 */
function getGeminiTTSConfig(series?: Series): GeminiTTSConfig {
  const defaultVoice = getValidVoice(series?.default_voice_name, DEFAULT_SPEAKER);
  const enableAlternation = series?.enable_voice_alternation === true;

  // Get prompt from series or use difficulty-based default
  let defaultPrompt: string;
  if (series?.gemini_tts_prompt) {
    defaultPrompt = `Generate speech in English. ${series.gemini_tts_prompt}`;
  } else {
    defaultPrompt = getDefaultPrompt(series?.difficulty_level);
  }

  let alternateVoice: string | undefined;
  let alternatePrompt: string | undefined;

  if (enableAlternation) {
    alternateVoice = getValidVoice(series?.alternate_voice_name, 'Kore');

    if (series?.gemini_tts_alt_prompt) {
      alternatePrompt = `Generate speech in English. ${series.gemini_tts_alt_prompt}`;
    } else {
      const { defaultVoicePrompt, alternateVoicePrompt } = getAlternationPrompts();
      defaultPrompt = defaultVoicePrompt;
      alternatePrompt = alternateVoicePrompt;
    }
  }

  return {
    speaker: defaultVoice,
    prompt: defaultPrompt,
    alternateSpeaker: alternateVoice,
    alternatePrompt: alternatePrompt,
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
  contextLines?: { allLines: string[]; currentIndex: number }
): Promise<Buffer> {
  const accessToken = await getCachedToken();

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
      languageCode: LANGUAGE_CODE,
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
    languageCode: LANGUAGE_CODE,
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

  const audioBuffer = Buffer.from(data.audioContent, 'base64');

  logger.debug('Successfully synthesized speech', {
    audioSizeBytes: audioBuffer.length,
  });

  return audioBuffer;
}

/**
 * Generates audio for a SINGLE sentence using Gemini-TTS
 */
async function generateSentenceAudio(
  text: string,
  speaker: string,
  prompt: string,
  sentenceIndex: number,
  totalSentences: number
): Promise<{ audioBuffer: Buffer; duration: number; voiceUsed: string }> {
  logger.info(`Generating audio for sentence ${sentenceIndex + 1}/${totalSentences}`, {
    textPreview: text.substring(0, 60) + (text.length > 60 ? '...' : ''),
    textLength: text.length,
    speaker
  });

  const audioBuffer = await retryWithBackoff(
    async () => synthesizeSpeech(text, speaker, prompt, undefined),
    `Gemini-TTS sentence ${sentenceIndex + 1}/${totalSentences}`,
    3,
    1000
  );

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
 * Generates INDIVIDUAL English audio files for each sentence using Gemini-TTS
 * Supports voice alternation when enabled in series configuration
 *
 * @param lines - Array of English text lines to convert to speech
 * @param series - Optional series object with custom prompts and voice configuration
 */
export async function generateAudioFiles(
  lines: string[],
  series?: Series
): Promise<AudioFile[]> {
  try {
    logger.info(`Generating ${lines.length} individual English audio files`, {
      seriesId: series?.id,
      seriesName: series?.name,
      voiceAlternationEnabled: series?.enable_voice_alternation || false,
    });

    const config = getGeminiTTSConfig(series);

    logger.info('Voice configuration', {
      defaultVoice: config.speaker,
      alternateVoice: config.alternateSpeaker,
      alternationEnabled: config.enableAlternation,
      hasCustomPrompt: !!series?.gemini_tts_prompt,
      hasCustomAltPrompt: !!series?.gemini_tts_alt_prompt,
    });

    const rateLimiter = new RateLimiter(10, 1000);
    const audioFiles: AudioFile[] = [];

    const estimatedTimeSeconds = lines.length * 7;
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

      if (i > 0) {
        await rateLimiter.waitIfNeeded();
      }

      const { audioBuffer, duration, voiceUsed } = await generateSentenceAudio(
        line,
        selectedVoice,
        selectedPrompt,
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
      });

      logger.info(`✓ Sentence ${i + 1}/${lines.length} completed`, {
        fileName: `sentence_${i}.mp3`,
        voice: voiceUsed,
        sizeKB: (audioBuffer.length / 1024).toFixed(1),
        duration: `${duration}s`
      });
    }

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
  return Math.max(duration, 1);
}
