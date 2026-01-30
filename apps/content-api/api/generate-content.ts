import type { VercelRequest, VercelResponse } from '@vercel/node';
import { z } from 'zod';
import { generateMultiLanguageContent } from '../src/services/gemini';
import { generateAudioFiles } from '../src/services/gemini-tts';
import { storeLessonData, checkIfTodayContentExists, getDefaultSeriesId, getSeriesById, getOrCreateChannel, getAllActiveSeries, getSeriesByBatch, storeGenerationLog } from '../src/services/supabase';
import type { GenerationResult, LanguageCode, SeriesGenerationResult } from '../src/types/index';
import { Logger } from '../src/utils/logger';
import crypto from 'crypto';

const logger = new Logger('GenerateContent');

/**
 * Request parameter validation schema
 * Ensures API inputs are safe and well-formed
 */
const requestSchema = z.object({
  series_ids: z
    .array(z.string().uuid('Invalid UUID format for series_id'))
    .max(20, 'Maximum 20 series IDs allowed')
    .optional(),
  batch: z
    .number()
    .int('Batch must be an integer')
    .min(1, 'Batch must be >= 1')
    .max(100, 'Batch must be <= 100')
    .optional(),
}).refine(
  (data) => {
    // At least one parameter should be provided, or neither (for default behavior)
    return true;
  },
  { message: 'Invalid request parameters' }
);

/**
 * Main Vercel serverless function
 * Generates daily English learning content about special days using Gemini AI
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  const startTime = Date.now();

  // Determine trigger type early (needed for logging in both success and error cases)
  const authHeader = req.headers.authorization;
  const isCronJob = authHeader === `Bearer ${process.env.CRON_SECRET}`;
  const triggerType: 'cron' | 'manual' | 'api' = isCronJob ? 'cron' : 'manual';

  try {
    logger.info('=== Starting content generation ===');

    // Verify this is a POST request or cron trigger
    if (req.method !== 'POST' && req.method !== 'GET') {
      res.status(405).json({
        success: false,
        error: 'Method not allowed',
        message: 'Only POST and GET requests are allowed',
      } as GenerationResult);
      return;
    }

    // Check authorization for non-cron requests
    // Vercel cron jobs include a special header

    if (!isCronJob && req.method === 'POST') {
      // Verify manual trigger authorization
      const providedSecret = req.headers['x-api-secret'] || req.query.secret;
      const apiSecret = process.env.API_SECRET;

      if (!apiSecret || providedSecret !== apiSecret) {
        logger.warn('Unauthorized access attempt', {
          apiSecretSet: !!apiSecret,
          providedSecretSet: !!providedSecret,
        });
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'Invalid or missing API secret',
        } as GenerationResult);
        return;
      }
    }

    // Extract and validate series_ids or batch from request
    const requestBody = req.body || {};
    const rawBatch = requestBody.batch || req.query.batch;
    const rawSeriesIds = requestBody.series_ids || req.query.series_ids;

    // Validate input parameters
    const validationResult = requestSchema.safeParse({
      series_ids: rawSeriesIds ? (Array.isArray(rawSeriesIds) ? rawSeriesIds : [rawSeriesIds]) : undefined,
      batch: rawBatch ? parseInt(String(rawBatch), 10) : undefined,
    });

    if (!validationResult.success) {
      logger.warn('Invalid request parameters', {
        errors: validationResult.error.format(),
      });
      res.status(400).json({
        success: false,
        error: 'Invalid request parameters',
        message: validationResult.error.errors.map(e => `${e.path.join('.')}: ${e.message}`).join('; '),
      } as GenerationResult);
      return;
    }

    const { series_ids: seriesIdsParam, batch: batchParam } = validationResult.data;

    let seriesIds: string[];
    if (seriesIdsParam && seriesIdsParam.length > 0) {
      // Explicit series_ids provided (manual trigger)
      seriesIds = seriesIdsParam;
      logger.info('Using provided series IDs', { seriesIds });
    } else if (batchParam !== undefined) {
      // Batch number provided (cron trigger)
      logger.info('Fetching series for batch', { batch: batchParam });
      const allSeries = await getSeriesByBatch(batchParam);
      seriesIds = allSeries.map(s => s.id);
      logger.info(`Found ${allSeries.length} series in batch ${batchParam}`, {
        seriesIds,
        seriesNames: allSeries.map(s => s.name)
      });
    } else {
      // No batch or series_ids: fetch ALL active series (backward compatible)
      logger.info('No batch or series_ids provided, fetching all active series');
      const allSeries = await getAllActiveSeries();
      seriesIds = allSeries.map(s => s.id);
      logger.info(`Found ${allSeries.length} active series`, {
        seriesIds,
        seriesNames: allSeries.map(s => s.name)
      });
    }

    logger.info('Processing series', { count: seriesIds.length, seriesIds });

    const languages: LanguageCode[] = ['en', 'ja', 'fr'];
    const results: SeriesGenerationResult['results'] = [];
    const errors: string[] = [];
    const generationStartTime = Date.now(); // Track execution time for timeout monitoring
    const VERCEL_TIMEOUT_MS = 600000; // 10 minutes
    const TIMEOUT_BUFFER_MS = 60000; // 1 minute buffer for cleanup

    // Process each series COMPLETELY INDEPENDENTLY
    // Each series will have its own isolated AI generation context
    for (let i = 0; i < seriesIds.length; i++) {
      const seriesId = seriesIds[i];

      try {
        logger.info(`\n${'='.repeat(80)}`);
        logger.info(`Processing Series ${i + 1}/${seriesIds.length}: ${seriesId}`);
        logger.info(`${'='.repeat(80)}\n`);

        // Fetch series data
        const series = await getSeriesById(seriesId);
        if (!series) {
          const errorMsg = `Series not found: ${seriesId}`;
          logger.error(errorMsg);
          errors.push(errorMsg);
          continue;
        }

        logger.info(`Series loaded: ${series.name}`, {
          concept: series.concept,
          lineCount: series.line_count,
          difficulty: series.difficulty_level,
        });

        // Get or create channels for each language in this series
        logger.info(`Getting/creating channels for series: ${series.name}`);
        const seriesChannels: Record<LanguageCode, string> = {} as Record<LanguageCode, string>;

        for (const language of languages) {
          const channelId = await getOrCreateChannel(language, seriesId);
          seriesChannels[language] = channelId;
          logger.debug(`Channel ready for ${language}: ${channelId}`);
        }

        // Check which languages need content for this series
        const existingLanguages: LanguageCode[] = [];
        for (const language of languages) {
          const channelId = seriesChannels[language];
          const contentExists = await checkIfTodayContentExists(language, channelId);
          if (contentExists) {
            existingLanguages.push(language);
          }
        }

        const languagesToGenerate = languages.filter(lang => !existingLanguages.includes(lang));

        if (languagesToGenerate.length === 0) {
          logger.info(`Content already exists for series ${series.name}, skipping`);
          continue;
        }

        logger.info(`Generating content for ${series.name}`, {
          languagesToGenerate,
          existingLanguages
        });

        // Calculate estimated time for this series
        const sentenceCount = series.line_count || 10;
        const ttsCallsPerLanguage = sentenceCount;
        const totalTTSCalls = ttsCallsPerLanguage * languagesToGenerate.length;
        const estimatedTTSTimeSeconds = totalTTSCalls * 7; // 7 seconds per TTS call (6s min + 1s buffer)
        const estimatedTotalTimeMinutes = Math.ceil((estimatedTTSTimeSeconds + 60) / 60); // Add 1 min for content generation

        logger.info(`Series generation time estimate`, {
          sentences: sentenceCount,
          languages: languagesToGenerate.length,
          totalTTSCalls: totalTTSCalls,
          estimatedTimeMinutes: estimatedTotalTimeMinutes,
        });

        // Timeout protection: check if we have enough time remaining
        const elapsedTime = Date.now() - generationStartTime;
        const remainingTime = VERCEL_TIMEOUT_MS - elapsedTime;
        const estimatedTimeNeeded = estimatedTTSTimeSeconds * 1000; // Convert to ms

        if (estimatedTimeNeeded > remainingTime - TIMEOUT_BUFFER_MS) {
          const warningMsg = `⚠️ WARNING: Insufficient time remaining for series ${series.name}. Estimated: ${estimatedTotalTimeMinutes}min, Remaining: ${Math.floor(remainingTime / 60000)}min`;
          logger.warn(warningMsg);
          errors.push(warningMsg);
          continue; // Skip this series to avoid timeout
        }

        // Generate content group ID for this series (links all language versions)
        const contentGroupId = crypto.randomUUID();

        // Step 1: Generate multi-language content using Gemini AI
        logger.info(`Generating multi-language content for ${series.name}...`);
        const multiLangContent = await generateMultiLanguageContent(new Date(), series);
        logger.info('Multi-language content generated successfully', {
          seriesName: series.name,
          englishTitle: multiLangContent.en.title,
          japaneseTitle: multiLangContent.ja.title,
          frenchTitle: multiLangContent.fr.title,
        });

        const sourceUrl = `AI Generated - ${series.name} (${new Date().toLocaleDateString('en-US')})`;
        const seriesLessons: Record<string, { lessonId: string; sentenceCount: number }> = {};

        // Step 2 & 3: Generate audio and store for each language
        for (const language of languagesToGenerate) {
          try {
            const content = multiLangContent[language];
            const channelId = seriesChannels[language];

            const languageTTSCalls = content.lines.length;
            const estimatedLanguageTimeMin = Math.ceil((languageTTSCalls * 7) / 60);

            logger.info(`Generating ${languageTTSCalls} audio files for ${series.name} - ${language.toUpperCase()}`, {
              sentenceCount: content.lines.length,
              estimatedTimeMinutes: estimatedLanguageTimeMin,
            });

            // Generate audio files using Gemini-TTS (sentence-by-sentence with rate limiting)
            const audioFiles = await generateAudioFiles(content.lines, language, series);

            logger.info(`Audio files generated`, {
              language,
              fileCount: audioFiles.length,
              voicesUsed: [...new Set(audioFiles.map(f => f.voiceUsed || 'unknown'))]
            });

            logger.info(`Storing ${language.toUpperCase()} data in Supabase...`);
            const lessonId = await storeLessonData(
              content,
              audioFiles,
              sourceUrl,
              language,
              channelId,
              contentGroupId
            );

            seriesLessons[language] = {
              lessonId,
              sentenceCount: content.lines.length
            };

            logger.info(`${language.toUpperCase()} data stored successfully`, { lessonId });

          } catch (langError) {
            const errorMsg = `Failed to generate ${language.toUpperCase()} for series ${series.name}: ${langError instanceof Error ? langError.message : 'Unknown error'}`;
            logger.error(errorMsg);
            errors.push(errorMsg);
            // Continue with next language instead of failing entire series
            continue;
          }

          // Add delay between languages to avoid quota exhaustion
          const isLastLanguage = languagesToGenerate.indexOf(language) === languagesToGenerate.length - 1;
          if (!isLastLanguage) {
            logger.info('Waiting 10 seconds before processing next language...');
            await new Promise(resolve => setTimeout(resolve, 10000));
          }
        }

        // Only add to results if at least one language succeeded
        if (Object.keys(seriesLessons).length > 0) {
          results.push({
            seriesId,
            seriesName: series.name,
            lessons: seriesLessons
          });
        }

        logger.info(`${'='.repeat(80)}`);
        logger.info(`✓ Completed series ${i + 1}/${seriesIds.length}: ${series.name}`);
        logger.info(`${'='.repeat(80)}\n`);

        // Add a delay between series to reduce API pressure and ensure stability
        if (i < seriesIds.length - 1) {
          logger.info('Waiting 5 seconds before processing next series...\n');
          await new Promise(resolve => setTimeout(resolve, 5000));
        }

      } catch (error) {
        const errorMsg = `Failed to generate content for series ${seriesId}: ${error instanceof Error ? error.message : 'Unknown error'}`;
        logger.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    const duration = Date.now() - startTime;
    logger.info('=== Multi-series content generation completed ===', {
      duration: `${duration}ms`,
      seriesCount: results.length,
      errors: errors.length,
    });

    // Store generation log in Supabase
    await storeGenerationLog(triggerType, seriesIds, results, errors, duration);

    // Return results
    res.status(200).json({
      success: results.length > 0,
      results,
      errors: errors.length > 0 ? errors : undefined,
      message: `Generated content for ${results.length} series`,
    } as SeriesGenerationResult);

  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('=== Content generation failed ===', error);
    logger.info('Duration before failure', { duration: `${duration}ms` });

    // Store generation log for failed run
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Try to store log (don't throw if this fails)
    try {
      await storeGenerationLog(
        triggerType,
        [], // seriesIds might not be available if error occurred early
        [], // no results on failure
        [errorMessage],
        duration
      );
    } catch (logError) {
      logger.error('Failed to store error log', logError);
    }

    res.status(500).json({
      success: false,
      error: errorMessage,
      message: 'Failed to generate content',
    } as GenerationResult);
  }
}
