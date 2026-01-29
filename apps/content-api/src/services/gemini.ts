import { GoogleGenerativeAI } from '@google/generative-ai';
import type { NewsArticle, SummarizedContent, MultiLanguageContent, LanguageCode, Series } from '../types/index';
import { Logger } from '../utils/logger';
import { retryWithBackoff } from '../utils/retry';

const logger = new Logger('Gemini');

/**
 * Generates educational content about special days/events using Gemini AI
 * Creates a lesson formatted line-by-line for language learning based on series configuration
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

    // Create a completely fresh Gemini AI instance for this series
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      // Each request is completely isolated
    });

    // Format the date for the prompt
    const dateStr = date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    // Use series configuration or defaults
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
      2,    // maxRetries
      5000  // baseDelay (5 seconds)
    );
    const response = result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Gemini returned empty response');
    }

    logger.info('Received response from Gemini', {
      responseLength: text.length,
    });

    // Parse the response into lines
    const allLines = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        // Remove numbering from the start of lines (e.g., "1. ", "2. ", etc.)
        // but keep the actual content
        return line.replace(/^[\d]+[\.\)]\s*/, '');
      })
      .filter(line => line.length > 0); // Filter again after removing numbering

    if (allLines.length === 0) {
      throw new Error('Failed to parse Gemini response into lines');
    }

    // Extract title (first line) and content lines
    const title = allLines[0];
    const lines = allLines.slice(1); // Rest are content lines

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
 * Summarizes news article using Gemini AI
 * Creates a 100-150 word summary formatted line-by-line for English learning
 */
export async function summarizeArticle(article: NewsArticle): Promise<SummarizedContent> {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }

    logger.info('Initializing Gemini AI for summarization...');

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `You are an English learning content creator. Your task is to summarize the following news article into 100-150 words for English learners.

IMPORTANT FORMATTING REQUIREMENTS:
1. Create a summary that is exactly 100-150 words
2. Break the summary into SHORT sentences or phrases (10-20 words each)
3. Put each sentence/phrase on a NEW LINE
4. Use simple, clear English suitable for intermediate learners
5. Each line should be a complete thought that can stand alone
6. Do NOT use bullet points or numbering
7. Just put one sentence per line

Article Title: ${article.title}

Article Content:
${article.content}

Please provide the summary now, with each sentence on a new line:`;

    logger.info('Sending request to Gemini AI...');

    const result = await retryWithBackoff(
      () => model.generateContent(prompt),
      `Gemini article summarization for "${article.title}"`,
      2,    // maxRetries
      5000  // baseDelay (5 seconds)
    );
    const response = result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Gemini returned empty response');
    }

    logger.info('Received response from Gemini', {
      responseLength: text.length,
    });

    // Parse the response into lines
    const lines = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .filter(line => !line.match(/^[\*\-\d]+[\.\)]/)); // Remove bullet points/numbering if any

    if (lines.length === 0) {
      throw new Error('Failed to parse Gemini response into lines');
    }

    logger.info('Successfully parsed summary', {
      lineCount: lines.length,
      wordCount: text.split(/\s+/).length,
    });

    return {
      title: article.title,
      summary: text,
      lines,
    };

  } catch (error) {
    logger.error('Error in Gemini summarization', error);
    throw new Error(`Failed to summarize article: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Translates English content to a target language
 * Maintains the line-by-line structure for language learning
 */
export async function translateContent(
  content: SummarizedContent,
  targetLanguage: 'ja' | 'fr'
): Promise<SummarizedContent> {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }

    const languageNames = {
      ja: 'Japanese',
      fr: 'French'
    };

    const languageName = languageNames[targetLanguage];

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
      2,    // maxRetries
      5000  // baseDelay (5 seconds)
    );
    const response = result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Gemini returned empty response for translation');
    }

    logger.info(`Received translation response for ${languageName}`, {
      responseLength: text.length,
    });

    // Parse the response into lines
    const allLines = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        // Remove numbering from the start of lines (e.g., "1. ", "2. ", etc.)
        // but keep the actual content
        return line.replace(/^[\d]+[\.\)]\s*/, '');
      })
      .filter(line => line.length > 0); // Filter again after removing numbering

    if (allLines.length === 0) {
      throw new Error(`Failed to parse ${languageName} translation into lines`);
    }

    // Extract title (first line) and content lines
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
 * Generates multi-language content for all supported languages
 * Creates English content first, then translates to Japanese and French
 */
export async function generateMultiLanguageContent(date: Date = new Date(), series?: Series): Promise<MultiLanguageContent> {
  try {
    logger.info('Starting multi-language content generation...', {
      date: date.toISOString(),
      seriesName: series?.name || 'default'
    });

    // Step 1: Generate English content
    logger.info('Generating English content...');
    const englishContent = await generateSpecialDayContent(date, series);

    // Step 2: Translate to Japanese
    logger.info('Translating to Japanese...');
    const japaneseContent = await translateContent(englishContent, 'ja');

    // Step 3: Translate to French
    logger.info('Translating to French...');
    const frenchContent = await translateContent(englishContent, 'fr');

    logger.info('Successfully generated content for all languages', {
      languages: ['en', 'ja', 'fr'],
      englishLines: englishContent.lines.length,
      japaneseLines: japaneseContent.lines.length,
      frenchLines: frenchContent.lines.length,
    });

    return {
      en: englishContent,
      ja: japaneseContent,
      fr: frenchContent,
    };

  } catch (error) {
    logger.error('Error in multi-language content generation', error);
    throw new Error(`Failed to generate multi-language content: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
