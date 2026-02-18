import type { VercelRequest, VercelResponse } from '@vercel/node';
import { z } from 'zod';
import { generateMultiLanguageContent } from '../src/services/gemini';
import { generateAudioFiles } from '../src/services/gemini-tts';
import { storeLessonData, storeTranslations, checkIfTodayContentExists, getSeriesById, getOrCreateChannel, getAllActiveSeries, getSeriesByBatch, storeGenerationLog } from '../src/services/supabase';
import type { GenerationResult, SeriesGenerationResult } from '../src/types/index';
import { TRANSLATION_LANGUAGES } from '../src/types/index';
import { Logger } from '../src/utils/logger';
import crypto from 'crypto';

const logger = new Logger('GenerateContent');

/**
 * Request parameter validation schema
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
  translation_languages: z
    .array(z.string())
    .max(10, 'Maximum 10 translation languages allowed')
    .optional(),
}).refine(
  () => true,
  { message: 'Invalid request parameters' }
);

/**
 * Main Vercel serverless function
 * Generates daily English learning content using Gemini AI
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  const startTime = Date.now();
  const requestId = crypto.randomUUID();

  const authHeader = req.headers.authorization;
  const isCronJob = authHeader === `Bearer ${process.env.CRON_SECRET}`;
  const triggerType: 'cron' | 'manual' | 'api' = isCronJob ? 'cron' : 'manual';

  try {
    logger.info('=== Starting content generation ===', { requestId, triggerType });

    if (req.method !== 'POST' && req.method !== 'GET') {
      res.status(405).json({
        success: false,
        error: 'Method not allowed',
        message: 'Only POST and GET requests are allowed',
      } as GenerationResult);
      return;
    }

    if (!isCronJob && req.method === 'POST') {
      const providedSecret = req.headers['x-api-secret'] || req.query.secret;
      const apiSecret = process.env.API_SECRET;

      if (!apiSecret || providedSecret !== apiSecret) {
        logger.warn('Unauthorized access attempt');
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'Invalid or missing API secret',
        } as GenerationResult);
        return;
      }
    }

    // Extract and validate parameters
    const requestBody = req.body || {};
    const rawBatch = requestBody.batch || req.query.batch;
    const rawSeriesIds = requestBody.series_ids || req.query.series_ids;
    const rawTranslationLanguages = requestBody.translation_languages;

    const validationResult = requestSchema.safeParse({
      series_ids: rawSeriesIds ? (Array.isArray(rawSeriesIds) ? rawSeriesIds : [rawSeriesIds]) : undefined,
      batch: rawBatch ? parseInt(String(rawBatch), 10) : undefined,
      translation_languages: rawTranslationLanguages,
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

    const { series_ids: seriesIdsParam, batch: batchParam, translation_languages: translationLanguagesParam } = validationResult.data;
    const translationLanguages = translationLanguagesParam ?? TRANSLATION_LANGUAGES;

    let seriesIds: string[];
    if (seriesIdsParam && seriesIdsParam.length > 0) {
      seriesIds = seriesIdsParam;
      logger.info('Using provided series IDs', { seriesIds });
    } else if (batchParam !== undefined) {
      logger.info('Fetching series for batch', { batch: batchParam });
      const allSeries = await getSeriesByBatch(batchParam);
      seriesIds = allSeries.map(s => s.id);
      logger.info(`Found ${allSeries.length} series in batch ${batchParam}`, {
        seriesIds,
        seriesNames: allSeries.map(s => s.name)
      });
    } else {
      logger.info('No batch or series_ids provided, fetching all active series');
      const allSeries = await getAllActiveSeries();
      seriesIds = allSeries.map(s => s.id);
      logger.info(`Found ${allSeries.length} active series`, {
        seriesIds,
        seriesNames: allSeries.map(s => s.name)
      });
    }

    logger.info('Processing series', { count: seriesIds.length, seriesIds });

    const results: SeriesGenerationResult['results'] = [];
    const errors: string[] = [];
    const generationStartTime = Date.now();
    const VERCEL_TIMEOUT_MS = 600000;
    const TIMEOUT_BUFFER_MS = 60000;

    // Process each series
    for (let i = 0; i < seriesIds.length; i++) {
      const seriesId = seriesIds[i];

      try {
        logger.info(`\n${'='.repeat(80)}`);
        logger.info(`Processing Series ${i + 1}/${seriesIds.length}: ${seriesId}`);
        logger.info(`${'='.repeat(80)}\n`);

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

        // Get or create ONE channel per series (no language variants)
        const channelId = await getOrCreateChannel(seriesId);
        logger.debug(`Channel ready: ${channelId}`);

        // Idempotency check
        const contentExists = await checkIfTodayContentExists(channelId);
        if (contentExists) {
          logger.info(`Idempotency: Content already exists for series ${series.name}, skipping`, {
            requestId,
            seriesId,
            channelId,
            date: new Date().toISOString().split('T')[0],
          });
          continue;
        }

        // Time estimate
        const sentenceCount = series.line_count || 10;
        const estimatedTTSTimeSeconds = sentenceCount * 7;
        const estimatedTotalTimeMinutes = Math.ceil((estimatedTTSTimeSeconds + 60) / 60);

        logger.info(`Generation time estimate`, {
          sentences: sentenceCount,
          estimatedTimeMinutes: estimatedTotalTimeMinutes,
          translationLanguages: [...translationLanguages],
        });

        // Timeout protection
        const elapsedTime = Date.now() - generationStartTime;
        const remainingTime = VERCEL_TIMEOUT_MS - elapsedTime;
        const estimatedTimeNeeded = estimatedTTSTimeSeconds * 1000;

        if (estimatedTimeNeeded > remainingTime - TIMEOUT_BUFFER_MS) {
          const warningMsg = `WARNING: Insufficient time remaining for series ${series.name}. Estimated: ${estimatedTotalTimeMinutes}min, Remaining: ${Math.floor(remainingTime / 60000)}min`;
          logger.warn(warningMsg);
          errors.push(warningMsg);
          continue;
        }

        // Step 1: Generate English content + translations
        logger.info(`Generating content for ${series.name}...`);
        const multiLangContent = await generateMultiLanguageContent(new Date(), series, translationLanguages);
        logger.info('Content generated successfully', {
          seriesName: series.name,
          englishTitle: multiLangContent.en.title,
          translationLanguages: Object.keys(multiLangContent.translations),
        });

        const sourceUrl = `AI Generated - ${series.name} (${new Date().toLocaleDateString('en-US')})`;

        // Step 2: Generate English audio
        logger.info(`Generating ${multiLangContent.en.lines.length} audio files for ${series.name}...`);
        const audioFiles = await generateAudioFiles(multiLangContent.en.lines, series);

        logger.info(`English audio files generated`, {
          fileCount: audioFiles.length,
          voicesUsed: [...new Set(audioFiles.map(f => f.voiceUsed || 'unknown'))]
        });

        // Step 3: Store English lesson
        logger.info(`Storing English lesson in Supabase...`);
        const { lessonId, sentenceIds } = await storeLessonData(
          multiLangContent.en,
          audioFiles,
          sourceUrl,
          channelId
        );

        logger.info(`English lesson stored`, { lessonId });

        // Step 4: Store translations
        if (Object.keys(multiLangContent.translations).length > 0) {
          logger.info(`Storing translations...`);
          await storeTranslations(lessonId, sentenceIds, multiLangContent.translations);
          logger.info(`Translations stored successfully`);
        }

        results.push({
          seriesId,
          seriesName: series.name,
          lessonId,
          sentenceCount: multiLangContent.en.lines.length,
          translationLanguages: Object.keys(multiLangContent.translations),
        });

        logger.info(`${'='.repeat(80)}`);
        logger.info(`✓ Completed series ${i + 1}/${seriesIds.length}: ${series.name}`);
        logger.info(`${'='.repeat(80)}\n`);

        // Delay between series
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
    logger.info('=== Content generation completed ===', {
      duration: `${duration}ms`,
      seriesCount: results.length,
      errors: errors.length,
    });

    await storeGenerationLog(triggerType, seriesIds, results, errors, duration);

    res.status(200).json({
      success: results.length > 0,
      results,
      errors: errors.length > 0 ? errors : undefined,
      message: `Generated content for ${results.length} series`,
    } as SeriesGenerationResult);

  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('=== Content generation failed ===', error);

    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    try {
      await storeGenerationLog(triggerType, [], [], [errorMessage], duration);
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
