import { GoogleGenerativeAI } from '@google/generative-ai';
import type { SummarizedContent, MultiLanguageContent, Series } from '../types/index';
import { TRANSLATION_LANGUAGES } from '../types/index';
import { Logger } from '../utils/logger';
import { retryWithBackoff } from '../utils/retry';

const logger = new Logger('Gemini');

/**
 * Language name mapping for translation prompts
 * Add new languages here as needed
 */
const LANGUAGE_NAMES: Record<string, string> = {
  ja: 'Japanese',
  fr: 'French',
  ko: 'Korean',
  'zh-Hans': 'Chinese (Simplified)',
  'zh-Hant': 'Chinese (Traditional)',
  es: 'Spanish',
  de: 'German',
  pt: 'Portuguese',
  it: 'Italian',
  ar: 'Arabic',
  hi: 'Hindi',
};

/**
 * Generates educational content about special days/events using Gemini AI
 * Creates a lesson formatted line-by-line for English language learning
 */
export async function generateSpecialDayContent(date: Date = new Date(), series?: Series): Promise<SummarizedContent> {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }

    logger.info('Initializing FRESH Gemini AI instance for content generation...', {
      date: date.toISOString(),
      seriesName: series?.name || 'default',
      seriesConcept: series?.concept ? series.concept.substring(0, 50) + '...' : 'N/A'
    });

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
    });

    const dateStr = date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    const lineCount = series?.line_count || 10;
    const difficulty = series?.difficulty_level || 'intermediate';
    const seriesConcept = series?.concept || 'Daily news content about special days and current events';
    const seriesName = series?.name || 'Daily Content';
    const additionalPrompt = series?.ai_generation_prompt || '';

    const prompt = `You are an English learning content creator. Your task is to create educational content about today's date: ${dateStr}.

IMPORTANT - SERIES CONTEXT:
This content is for the series: "${seriesName}"
Series concept: ${seriesConcept}

FOCUS EXCLUSIVELY on this series concept. Do NOT mix concepts from other series.

Research what special events, holidays, historical events, or interesting facts are associated with this date THAT FIT THIS SERIES CONCEPT, and create an engaging lesson for English learners.

CONTENT REQUIREMENTS:
1. Start with a compelling title about the special day/event
2. Create EXACTLY ${lineCount} lines of content (not including the title)
3. Focus on interesting historical events, holidays, celebrations, or notable facts about this date
4. Make it engaging and informative for ${difficulty} level English learners
5. Include cultural, historical, or scientific significance when relevant

IMPORTANT FORMATTING REQUIREMENTS:
1. Each line should be a SHORT sentence or phrase (10-20 words each)
2. Put each sentence/phrase on a NEW LINE
3. Use simple, clear English suitable for ${difficulty} learners
4. Each line should be a complete thought that can stand alone
5. Do NOT use bullet points or numbering
6. Just put one sentence per line
7. Generate EXACTLY ${lineCount} lines (one line will become one audio file)

${additionalPrompt ? `ADDITIONAL INSTRUCTIONS:\n${additionalPrompt}\n` : ''}
Please provide the content now, starting with a title on the first line, followed by the educational content with each sentence on a new line:`;

    logger.info('Sending request to Gemini AI...');

    const result = await retryWithBackoff(
      () => model.generateContent(prompt),
      `Gemini content generation for ${seriesName}`,
      2,
      5000
    );
    const response = result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Gemini returned empty response');
    }

    logger.info('Received response from Gemini', {
      responseLength: text.length,
    });

    const allLines = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        return line.replace(/^[\d]+[\.\)]\s*/, '');
      })
      .filter(line => line.length > 0);

    if (allLines.length === 0) {
      throw new Error('Failed to parse Gemini response into lines');
    }

    const title = allLines[0];
    const lines = allLines.slice(1);

    logger.info('Successfully parsed special day content', {
      title,
      lineCount: lines.length,
      wordCount: text.split(/\s+/).length,
    });

    return {
      title,
      summary: lines.join('\n'),
      lines,
    };

  } catch (error) {
    logger.error('Error in Gemini special day content generation', error);
    throw new Error(`Failed to generate special day content: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Translates English content to a target language
 * Maintains the line-by-line structure for language learning
 *
 * @param content - English content to translate
 * @param targetLanguage - Language code (e.g., 'ja', 'fr', 'ko')
 */
export async function translateContent(
  content: SummarizedContent,
  targetLanguage: string
): Promise<SummarizedContent> {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }

    const languageName = LANGUAGE_NAMES[targetLanguage] || targetLanguage;

    logger.info(`Translating content to ${languageName}...`, {
      originalTitle: content.title,
      lineCount: content.lines.length
    });

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `You are a professional translator. Translate the following English educational content into ${languageName}.

IMPORTANT REQUIREMENTS:
1. Translate the title (first line)
2. Translate each content line while maintaining the same line-by-line structure
3. Keep the same number of lines as the original
4. Maintain natural, fluent ${languageName} suitable for language learners
5. Preserve the meaning and educational value
6. Do NOT add bullet points, numbering, or any extra formatting
7. Output ONLY the translated lines, one per line

Original Content:
Title: ${content.title}

Lines:
${content.lines.map((line, i) => `${i + 1}. ${line}`).join('\n')}

Please provide the ${languageName} translation now, with the title on the first line, followed by each translated sentence on a new line:`;

    logger.info(`Sending translation request to Gemini AI for ${languageName}...`);

    const result = await retryWithBackoff(
      () => model.generateContent(prompt),
      `Gemini translation to ${languageName}`,
      2,
      5000
    );
    const response = result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Gemini returned empty response for translation');
    }

    logger.info(`Received translation response for ${languageName}`, {
      responseLength: text.length,
    });

    const allLines = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        return line.replace(/^[\d]+[\.\)]\s*/, '');
      })
      .filter(line => line.length > 0);

    if (allLines.length === 0) {
      throw new Error(`Failed to parse ${languageName} translation into lines`);
    }

    const translatedTitle = allLines[0];
    const translatedLines = allLines.slice(1);

    logger.info(`Successfully translated content to ${languageName}`, {
      title: translatedTitle,
      lineCount: translatedLines.length,
    });

    return {
      title: translatedTitle,
      summary: translatedLines.join('\n'),
      lines: translatedLines,
    };

  } catch (error) {
    logger.error(`Error translating content to ${targetLanguage}`, error);
    throw new Error(`Failed to translate content: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Generates English content and translations for all configured languages
 *
 * @param date - Date to generate content for
 * @param series - Optional series configuration
 * @param translationLanguages - Languages to translate into (defaults to TRANSLATION_LANGUAGES)
 */
export async function generateMultiLanguageContent(
  date: Date = new Date(),
  series?: Series,
  translationLanguages: readonly string[] = TRANSLATION_LANGUAGES
): Promise<MultiLanguageContent> {
  try {
    logger.info('Starting content generation...', {
      date: date.toISOString(),
      seriesName: series?.name || 'default',
      translationLanguages: [...translationLanguages],
    });

    // Step 1: Generate English content
    logger.info('Generating English content...');
    const englishContent = await generateSpecialDayContent(date, series);

    // Step 2: Translate to each configured language
    const translations: Record<string, SummarizedContent> = {};

    for (const lang of translationLanguages) {
      const languageName = LANGUAGE_NAMES[lang] || lang;
      logger.info(`Translating to ${languageName}...`);
      translations[lang] = await translateContent(englishContent, lang);
    }

    logger.info('Successfully generated content for all languages', {
      english: englishContent.lines.length,
      translations: Object.fromEntries(
        Object.entries(translations).map(([lang, content]) => [lang, content.lines.length])
      ),
    });

    return {
      en: englishContent,
      translations,
    };

  } catch (error) {
    logger.error('Error in content generation', error);
    throw new Error(`Failed to generate content: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
