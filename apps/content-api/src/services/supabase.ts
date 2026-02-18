import { createClient, SupabaseClient } from "@supabase/supabase-js";
import type {
  AudioFile,
  LessonRecord,
  SentenceRecord,
  SummarizedContent,
  Series,
  GenerationLogRecord,
  SeriesGenerationResult,
} from "../types/index";
import { TRANSLATION_LANGUAGES } from "../types/index";
import { translateChannelMetadata } from "./gemini";
import { estimateAudioDuration } from "./gemini-tts";
import { Logger } from "../utils/logger";

const logger = new Logger("Supabase");

/**
 * Creates a Supabase client instance
 */
function getSupabaseClient(): SupabaseClient {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables are required"
    );
  }

  return createClient(supabaseUrl, supabaseKey);
}

/**
 * Gets or creates a channel for a series (English only, one channel per series)
 */
export async function getOrCreateChannel(seriesId: string): Promise<string> {
  try {
    const supabase = getSupabaseClient();

    // Try to find existing channel
    const { data: existingChannel } = await supabase
      .from("channels")
      .select("id")
      .eq("series_id", seriesId)
      .limit(1)
      .single();

    if (existingChannel) {
      logger.debug(`Found existing channel for series ${seriesId}: ${existingChannel.id}`);
      return existingChannel.id;
    }

    // Channel doesn't exist, create it
    logger.info(`Creating new channel for series ${seriesId}`);

    const series = await getSeriesById(seriesId);
    if (!series) {
      throw new Error(`Series not found: ${seriesId}`);
    }

    const { data: newChannel, error: insertError } = await supabase
      .from("channels")
      .insert([{
        title: series.name,
        description: series.concept,
        icon_name: 'globe.europe.africa.fill',
        series_id: seriesId,
        cover_image_url: series.cover_image_url
      }])
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to create channel: ${insertError.message}`);
    }

    logger.info(`Created new channel: ${series.name}`, { id: newChannel.id });

    // Generate and store channel translations
    try {
      await generateAndStoreChannelTranslations(
        newChannel.id,
        series.name,
        series.concept
      );
    } catch (translationError) {
      // Don't fail channel creation if translations fail
      logger.warn(`Failed to generate channel translations for ${newChannel.id}`, translationError);
    }

    return newChannel.id;

  } catch (error) {
    logger.error(`Error getting or creating channel for series ${seriesId}`, error);
    throw error;
  }
}

/**
 * Checks if content for today already exists for a specific channel
 */
export async function checkIfTodayContentExists(
  channelId: string
): Promise<boolean> {
  try {
    const supabase = getSupabaseClient();
    const today = new Date().toISOString().split("T")[0];

    const { data, error } = await supabase
      .from("lessons")
      .select("id")
      .eq("date", today)
      .eq("channel_id", channelId)
      .limit(1);

    if (error) {
      throw error;
    }

    return data && data.length > 0;
  } catch (error) {
    logger.error("Error checking if today content exists", error);
    throw error;
  }
}

/**
 * Fetches a series by ID
 */
export async function getSeriesById(seriesId: string): Promise<Series | null> {
  try {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from("series")
      .select("*")
      .eq("id", seriesId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        logger.warn(`Series not found: ${seriesId}`);
        return null;
      }
      throw error;
    }

    logger.debug(`Fetched series: ${data.name}`, { seriesId });
    return data as Series;
  } catch (error) {
    logger.error("Error fetching series by ID", error);
    throw error;
  }
}

/**
 * Fetches all active series
 */
export async function getAllActiveSeries(): Promise<Series[]> {
  try {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from("series")
      .select("*")
      .order("name", { ascending: true });

    if (error) {
      throw error;
    }

    logger.debug(`Fetched ${data.length} series`);
    return data as Series[];
  } catch (error) {
    logger.error("Error fetching all series", error);
    throw error;
  }
}

/**
 * Fetches series by batch number
 */
export async function getSeriesByBatch(batchNumber: number): Promise<Series[]> {
  try {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from("series")
      .select("*")
      .eq("batch_number", batchNumber)
      .order("name", { ascending: true });

    if (error) {
      throw error;
    }

    logger.debug(`Fetched ${data.length} series for batch ${batchNumber}`);
    return data as Series[];
  } catch (error) {
    logger.error(`Error fetching series for batch ${batchNumber}`, error);
    throw error;
  }
}

/**
 * Fetches a series by name
 */
export async function getSeriesByName(name: string): Promise<Series | null> {
  try {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from("series")
      .select("*")
      .eq("name", name)
      .limit(1)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        logger.warn(`Series not found with name: ${name}`);
        return null;
      }
      throw error;
    }

    logger.debug(`Fetched series by name: ${name}`, { id: data.id });
    return data as Series;
  } catch (error) {
    logger.error(`Error fetching series by name: ${name}`, error);
    throw error;
  }
}

/**
 * Gets the default series ID
 */
export async function getDefaultSeriesId(): Promise<string> {
  try {
    const defaultSeriesName = process.env.DEFAULT_SERIES_NAME || 'What day is it today';

    logger.info(`Fetching default series: ${defaultSeriesName}`);
    const series = await getSeriesByName(defaultSeriesName);

    if (!series) {
      throw new Error(`Default series not found: ${defaultSeriesName}`);
    }

    logger.info(`Default series ID: ${series.id}`, { name: series.name });
    return series.id;
  } catch (error) {
    logger.error("Error getting default series ID", error);
    throw error;
  }
}

/**
 * Stores an English lesson and its sentences in Supabase
 * Returns the lesson ID and sentence IDs for subsequent translation storage
 */
export async function storeLessonData(
  content: SummarizedContent,
  audioFiles: AudioFile[],
  sourceUrl: string,
  channelId: string
): Promise<{ lessonId: string; sentenceIds: string[] }> {
  const supabase = getSupabaseClient();
  let lessonId: string | null = null;
  const uploadedFiles: string[] = [];

  try {
    logger.info("Storing English lesson data in Supabase...", { channelId });

    // 1. Create lesson record
    const today = new Date().toISOString().split("T")[0];
    const lessonRecord: LessonRecord = {
      title: content.title,
      source_url: sourceUrl,
      date: today,
      channel_id: channelId,
    };

    const { data: lessonData, error: lessonError } = await supabase
      .from("lessons")
      .insert([lessonRecord])
      .select()
      .single();

    if (lessonError) {
      if (lessonError.code === '23505' || lessonError.message.includes('unique constraint')) {
        throw new Error(`Content for ${today} already exists in channel ${channelId}. Skipping duplicate.`);
      }
      throw new Error(`Failed to insert lesson: ${lessonError.message}`);
    }

    lessonId = lessonData.id;
    logger.info("Lesson record created", { lessonId, title: content.title, channelId });

    // 2. Upload individual audio files for each sentence
    const bucketName = "audio-files";
    const timestamp = Date.now();
    const sentenceRecords: Omit<SentenceRecord, "id">[] = [];

    logger.info('Uploading individual sentence audio files', {
      sentenceCount: content.lines.length,
      audioFileCount: audioFiles.length,
    });

    for (let i = 0; i < content.lines.length; i++) {
      const line = content.lines[i];
      const audioFile = audioFiles.find(f => f.lineIndex === i);

      if (!audioFile) {
        throw new Error(`Missing audio file for sentence ${i}`);
      }

      const storagePath = `${channelId}/${lessonId}/sentence_${i}.mp3`;

      logger.debug(`Uploading sentence ${i} audio`, {
        path: storagePath,
        sizeBytes: audioFile.audioBuffer.length,
      });

      const { error: uploadError } = await supabase.storage
        .from(bucketName)
        .upload(storagePath, audioFile.audioBuffer, {
          contentType: 'audio/mpeg',
          cacheControl: "3600",
          upsert: true,
        });

      if (uploadError) {
        throw new Error(`Failed to upload sentence ${i} audio: ${uploadError.message}`);
      }

      uploadedFiles.push(storagePath);

      const { data: { publicUrl } } = supabase.storage
        .from(bucketName)
        .getPublicUrl(storagePath);

      const audioUrl = `${publicUrl}?v=${timestamp}`;

      sentenceRecords.push({
        lesson_id: lessonId!,
        order_index: i,
        text: line,
        audio_url: audioUrl,
        duration: audioFile.duration || estimateAudioDuration(line),
        voice_used: audioFile.voiceUsed,
        start_time: null,
        end_time: null,
      });

      logger.debug(`✓ Sentence ${i} uploaded`, { url: audioUrl });
    }

    // 3. Insert all sentence records
    const { data: sentencesData, error: sentencesError } = await supabase
      .from("sentences")
      .insert(sentenceRecords)
      .select();

    if (sentencesError) {
      throw new Error(`Failed to insert sentences: ${sentencesError.message}`);
    }

    const sentenceIds = sentencesData.map((s: { id: string }) => s.id);

    logger.info("All sentence records created with individual audio URLs", {
      count: sentencesData.length,
      totalAudioFiles: audioFiles.length,
    });

    return { lessonId, sentenceIds };
  } catch (error) {
    logger.error("Error storing lesson data", error);

    const cleanupErrors: string[] = [];

    // Rollback: Delete lesson if it was created
    if (lessonId) {
      logger.warn("Rolling back: Deleting lesson due to error", {
        lessonId,
        uploadedFilesCount: uploadedFiles.length,
        originalError: error instanceof Error ? error.message : String(error),
      });

      try {
        await supabase.from("lessons").delete().eq("id", lessonId);
        logger.info("✓ Lesson rolled back successfully", { lessonId });
      } catch (rollbackError) {
        const rollbackMsg = `Failed to rollback lesson ${lessonId}: ${
          rollbackError instanceof Error ? rollbackError.message : String(rollbackError)
        }`;
        logger.error(rollbackMsg, { lessonId });
        cleanupErrors.push(rollbackMsg);
      }

      if (uploadedFiles.length > 0) {
        logger.warn("Cleaning up uploaded audio files", {
          count: uploadedFiles.length,
          files: uploadedFiles,
        });

        try {
          const { error: storageError } = await supabase.storage
            .from("audio-files")
            .remove(uploadedFiles);

          if (storageError) {
            throw storageError;
          }

          logger.info("✓ Audio files cleaned up successfully", {
            count: uploadedFiles.length,
          });
        } catch (cleanupError) {
          const cleanupMsg = `Failed to cleanup ${uploadedFiles.length} audio files: ${
            cleanupError instanceof Error ? cleanupError.message : String(cleanupError)
          }`;
          logger.error(cleanupMsg, { files: uploadedFiles });
          cleanupErrors.push(cleanupMsg);
        }
      }
    }

    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    const fullMessage = cleanupErrors.length > 0
      ? `${errorMessage}. Cleanup issues: ${cleanupErrors.join('; ')}`
      : errorMessage;

    throw new Error(`Failed to store data in Supabase: ${fullMessage}`);
  }
}

/**
 * Stores translations for a lesson's title and sentences
 * Inserts into lesson_translations and sentence_translations tables
 *
 * @param lessonId - The English lesson ID
 * @param sentenceIds - Ordered array of English sentence IDs (matching order_index)
 * @param translations - Record of language code → translated content
 */
export async function storeTranslations(
  lessonId: string,
  sentenceIds: string[],
  translations: Record<string, SummarizedContent>
): Promise<void> {
  const supabase = getSupabaseClient();

  try {
    const languages = Object.keys(translations);
    logger.info("Storing translations...", { lessonId, languages });

    // 1. Insert lesson title translations
    const lessonTranslations = languages.map(lang => ({
      lesson_id: lessonId,
      language: lang,
      title: translations[lang].title,
    }));

    const { error: lessonTransError } = await supabase
      .from("lesson_translations")
      .insert(lessonTranslations);

    if (lessonTransError) {
      throw new Error(`Failed to insert lesson translations: ${lessonTransError.message}`);
    }

    logger.info("Lesson title translations stored", { languages });

    // 2. Insert sentence translations
    const sentenceTranslations: { sentence_id: string; language: string; text: string }[] = [];

    for (const lang of languages) {
      const translatedLines = translations[lang].lines;
      for (let i = 0; i < Math.min(translatedLines.length, sentenceIds.length); i++) {
        sentenceTranslations.push({
          sentence_id: sentenceIds[i],
          language: lang,
          text: translatedLines[i],
        });
      }
    }

    if (sentenceTranslations.length > 0) {
      const { error: sentenceTransError } = await supabase
        .from("sentence_translations")
        .insert(sentenceTranslations);

      if (sentenceTransError) {
        throw new Error(`Failed to insert sentence translations: ${sentenceTransError.message}`);
      }
    }

    logger.info("All translations stored successfully", {
      lessonTranslations: lessonTranslations.length,
      sentenceTranslations: sentenceTranslations.length,
    });

  } catch (error) {
    logger.error("Error storing translations", error);
    throw error;
  }
}

/**
 * Generates translations for channel title and description, then stores them
 */
async function generateAndStoreChannelTranslations(
  channelId: string,
  title: string,
  description: string
): Promise<void> {
  const translations: { channel_id: string; language: string; title: string; description: string }[] = [];

  for (const lang of TRANSLATION_LANGUAGES) {
    try {
      const translated = await translateChannelMetadata(title, description, lang);
      translations.push({
        channel_id: channelId,
        language: lang,
        title: translated.title,
        description: translated.description,
      });
    } catch (error) {
      logger.warn(`Skipping channel translation for ${lang}`, error);
    }
  }

  if (translations.length === 0) {
    logger.warn("No channel translations were generated");
    return;
  }

  const supabase = getSupabaseClient();

  const { error } = await supabase
    .from("channel_translations")
    .insert(translations);

  if (error) {
    throw new Error(`Failed to store channel translations: ${error.message}`);
  }

  logger.info("Channel translations stored", {
    channelId,
    languages: translations.map(t => t.language),
  });
}

/**
 * Stores a generation log record in Supabase
 */
export async function storeGenerationLog(
  triggerType: 'cron' | 'manual' | 'api',
  seriesIds: string[],
  results: SeriesGenerationResult['results'],
  errors: string[],
  durationMs: number
): Promise<void> {
  try {
    const supabase = getSupabaseClient();

    const seriesCount = results.length;
    let lessonsCreated = results.length; // One lesson per series
    let audioFilesGenerated = 0;

    for (const result of results) {
      audioFilesGenerated += result.sentenceCount;
    }

    let status: 'success' | 'partial' | 'failed';
    if (errors.length === 0) {
      status = 'success';
    } else if (results.length > 0) {
      status = 'partial';
    } else {
      status = 'failed';
    }

    const logRecord: Omit<GenerationLogRecord, 'id' | 'created_at'> = {
      trigger_type: triggerType,
      series_ids: seriesIds,
      status,
      duration_ms: durationMs,
      results: results.length > 0 ? results : null,
      errors: errors.length > 0 ? errors : null,
      series_count: seriesCount,
      lessons_created: lessonsCreated,
      audio_files_generated: audioFilesGenerated,
      metadata: {
        node_version: process.version,
        timestamp: new Date().toISOString(),
      },
    };

    const { error } = await supabase
      .from("generation_logs")
      .insert([logRecord]);

    if (error) {
      logger.error("Failed to store generation log", error);
    } else {
      logger.info("Generation log stored successfully", {
        status,
        seriesCount,
        lessonsCreated,
        audioFilesGenerated,
      });
    }
  } catch (error) {
    logger.error("Error storing generation log", error);
  }
}
