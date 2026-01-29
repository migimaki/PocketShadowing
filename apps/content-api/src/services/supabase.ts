import { createClient, SupabaseClient } from "@supabase/supabase-js";
import type {
  AudioFile,
  LessonRecord,
  SentenceRecord,
  SummarizedContent,
  LanguageCode,
  Series,
  GenerationLogRecord,
  SeriesGenerationResult,
} from "../types/index";
import { estimateAudioDuration } from "./gemini-tts";
import { Logger } from "../utils/logger";

const logger = new Logger("Supabase");

/**
 * Creates a Supabase client instance
 */
function getSupabaseClient(): SupabaseClient {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

  // Debug logging
  logger.debug("Environment check", {
    hasSupabaseUrl: !!supabaseUrl,
    hasSupabaseKey: !!supabaseKey,
    urlLength: supabaseUrl?.length || 0,
    keyLength: supabaseKey?.length || 0,
    availableEnvKeys: Object.keys(process.env).filter(k => k.includes('SUPABASE')),
  });

  if (!supabaseUrl || !supabaseKey) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables are required"
    );
  }

  return createClient(supabaseUrl, supabaseKey);
}

/**
 * Fetches channel IDs for all supported languages, optionally filtered by series
 */
export async function getChannelIdsByLanguage(seriesId?: string): Promise<Record<LanguageCode, string>> {
  try {
    const supabase = getSupabaseClient();
    const languages: LanguageCode[] = ['en', 'ja', 'fr'];

    const channelIds: Partial<Record<LanguageCode, string>> = {};

    for (const language of languages) {
      let query = supabase
        .from("channels")
        .select("id")
        .eq("language", language);

      // Filter by series if provided
      if (seriesId) {
        query = query.eq("series_id", seriesId);
      }

      const { data, error } = await query
        .limit(1)
        .single();

      if (error) {
        logger.warn(`Channel not found for language: ${language}${seriesId ? ` and series: ${seriesId}` : ''}`, error);
        continue;
      }

      if (data) {
        channelIds[language] = data.id;
        logger.debug(`Found channel for ${language}${seriesId ? ` (series: ${seriesId})` : ''}: ${data.id}`);
      }
    }

    // Verify all languages have channels
    const missingLanguages = languages.filter(lang => !channelIds[lang]);
    if (missingLanguages.length > 0) {
      throw new Error(`Missing channels for languages: ${missingLanguages.join(', ')}${seriesId ? ` (series: ${seriesId})` : ''}`);
    }

    logger.info('Successfully fetched all channel IDs', channelIds);
    return channelIds as Record<LanguageCode, string>;
  } catch (error) {
    logger.error("Error fetching channel IDs by language", error);
    throw error;
  }
}

/**
 * Gets or creates a channel for a specific language and series
 */
export async function getOrCreateChannel(language: LanguageCode, seriesId: string): Promise<string> {
  try {
    const supabase = getSupabaseClient();

    // Try to find existing channel
    const { data: existingChannel, error: fetchError } = await supabase
      .from("channels")
      .select("id")
      .eq("language", language)
      .eq("series_id", seriesId)
      .limit(1)
      .single();

    if (existingChannel) {
      logger.debug(`Found existing channel for ${language} / series ${seriesId}: ${existingChannel.id}`);
      return existingChannel.id;
    }

    // Channel doesn't exist, create it
    logger.info(`Creating new channel for ${language} / series ${seriesId}`);

    // Fetch series details for channel naming
    const series = await getSeriesById(seriesId);
    if (!series) {
      throw new Error(`Series not found: ${seriesId}`);
    }

    // Generate channel title based on language and series
    const languageNames: Record<LanguageCode, string> = {
      en: 'English',
      ja: '日本語',
      fr: 'Français'
    };

    const channelTitle = `${languageNames[language]} - ${series.name}`;
    const channelSubtitle = series.concept.substring(0, 100); // First 100 chars

    const { data: newChannel, error: insertError } = await supabase
      .from("channels")
      .insert([{
        title: channelTitle,
        subtitle: channelSubtitle,
        description: series.concept,
        icon_name: 'globe.europe.africa.fill',
        language: language,
        series_id: seriesId,
        cover_image_url: series.cover_image_url
      }])
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to create channel: ${insertError.message}`);
    }

    logger.info(`Created new channel: ${channelTitle}`, { id: newChannel.id });
    return newChannel.id;

  } catch (error) {
    logger.error(`Error getting or creating channel for ${language} / ${seriesId}`, error);
    throw error;
  }
}

/**
 * Checks if content for today already exists for a specific language and channel
 */
export async function checkIfTodayContentExists(
  language: LanguageCode,
  channelId: string
): Promise<boolean> {
  try {
    const supabase = getSupabaseClient();
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

    const { data, error } = await supabase
      .from("lessons")
      .select("id")
      .eq("date", today)
      .eq("language", language)
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
        // No rows returned
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
 * Used for multi-cron job scheduling to process different batches at different times
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
        // No rows returned
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
 * Gets the default series ID (dynamically fetched from database)
 */
export async function getDefaultSeriesId(): Promise<string> {
  try {
    // Default series name can be configured via environment variable
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
 * Stores lesson and sentences in Supabase
 * Note: series_id is now inherited from the channel
 */
export async function storeLessonData(
  content: SummarizedContent,
  audioFiles: AudioFile[],
  sourceUrl: string,
  language: LanguageCode,
  channelId: string,
  contentGroupId?: string
): Promise<string> {
  const supabase = getSupabaseClient();
  let lessonId: string | null = null;
  const uploadedFiles: string[] = [];

  try {
    logger.info("Storing lesson data in Supabase...", { language, channelId });

    // 1. Create lesson record first (so we have lessonId for audio path)
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const lessonRecord: LessonRecord = {
      title: content.title,
      source_url: sourceUrl,
      date: today,
      language,
      channel_id: channelId,
      content_group_id: contentGroupId,
    };

    const { data: lessonData, error: lessonError } = await supabase
      .from("lessons")
      .insert([lessonRecord])
      .select()
      .single();

    if (lessonError) {
      // Provide clearer error message for duplicate content
      if (lessonError.code === '23505' || lessonError.message.includes('unique constraint')) {
        throw new Error(`Content for ${language} on ${today} already exists in channel ${channelId}. Skipping duplicate.`);
      }
      throw new Error(`Failed to insert lesson: ${lessonError.message}`);
    }

    lessonId = lessonData.id;
    logger.info("Lesson record created", { lessonId, title: content.title, language, channelId });

    // 2. Upload INDIVIDUAL audio files for each sentence
    const bucketName = "audio-files";
    const timestamp = Date.now(); // Cache-busting parameter
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

      // Upload individual sentence audio file
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

      uploadedFiles.push(storagePath); // Track for potential rollback

      // Get public URL with cache-busting parameter
      const { data: { publicUrl } } = supabase.storage
        .from(bucketName)
        .getPublicUrl(storagePath);

      const audioUrl = `${publicUrl}?v=${timestamp}`;

      // Create sentence record with individual audio URL
      sentenceRecords.push({
        lesson_id: lessonId!,
        order_index: i,
        text: line,
        audio_url: audioUrl, // Individual sentence audio URL
        duration: audioFile.duration || estimateAudioDuration(line),
        voice_used: audioFile.voiceUsed,
        start_time: null, // Not needed for individual files
        end_time: null,   // Not needed for individual files
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

    logger.info("All sentence records created with individual audio URLs", {
      count: sentencesData.length,
      totalAudioFiles: audioFiles.length,
    });

    return lessonId;
  } catch (error) {
    logger.error("Error storing lesson data", error);

    // Rollback: Delete lesson if it was created
    if (lessonId) {
      logger.warn("Rolling back: Deleting lesson due to error", { lessonId });
      try {
        await supabase.from("lessons").delete().eq("id", lessonId);
        logger.info("Lesson rolled back successfully", { lessonId });
      } catch (rollbackError) {
        logger.error("Failed to rollback lesson", rollbackError);
      }

      // Attempt to clean up uploaded audio files
      if (uploadedFiles.length > 0) {
        logger.warn("Cleaning up uploaded audio files", { count: uploadedFiles.length });
        try {
          await supabase.storage.from("audio-files").remove(uploadedFiles);
          logger.info("Audio files cleaned up successfully");
        } catch (cleanupError) {
          logger.error("Failed to cleanup audio files", cleanupError);
        }
      }
    }

    throw new Error(
      `Failed to store data in Supabase: ${
        error instanceof Error ? error.message : "Unknown error"
      }`
    );
  }
}

/**
 * Stores a generation log record in Supabase
 * Logs content generation runs with results, errors, and statistics
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

    // Calculate statistics
    const seriesCount = results.length;
    let lessonsCreated = 0;
    let audioFilesGenerated = 0;

    for (const result of results) {
      const languageCount = Object.keys(result.lessons).length;
      lessonsCreated += languageCount;

      // Sum up sentence counts (each sentence = 1 audio file)
      for (const lessonData of Object.values(result.lessons)) {
        audioFilesGenerated += lessonData.sentenceCount;
      }
    }

    // Determine status
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
      // Log the error but don't throw - we don't want logging failures to break generation
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
    // Log the error but don't throw - logging is secondary to actual generation
    logger.error("Error storing generation log", error);
  }
}

/**
 * Database Schema SQL for reference (updated for multi-language support):
 *
 * CREATE TABLE channels (
 *   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   name TEXT NOT NULL,
 *   description TEXT,
 *   language VARCHAR(10) NOT NULL,
 *   icon_name TEXT,
 *   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 * );
 *
 * CREATE TABLE lessons (
 *   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   title TEXT NOT NULL,
 *   source_url TEXT NOT NULL,
 *   date DATE NOT NULL,
 *   language VARCHAR(10) NOT NULL,
 *   channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
 *   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
 *   CONSTRAINT unique_lesson_per_date_language_channel UNIQUE (date, language, channel_id)
 * );
 *
 * CREATE TABLE sentences (
 *   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
 *   order_index INTEGER NOT NULL,
 *   text TEXT NOT NULL,
 *   audio_url TEXT NOT NULL,
 *   duration INTEGER NOT NULL,
 *   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 * );
 *
 * CREATE INDEX idx_sentences_lesson_id ON sentences(lesson_id);
 * CREATE INDEX idx_lessons_date ON lessons(date);
 * CREATE INDEX idx_lessons_language ON lessons(language);
 * CREATE INDEX idx_lessons_channel_id ON lessons(channel_id);
 * CREATE INDEX idx_lessons_language_date ON lessons(language, date DESC);
 *
 * -- Storage bucket: audio-files (public)
 * -- Storage path: {channelId}/{lessonId}/line_XXX.mp3
 */
