//
//  LessonRepository.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import Supabase
import SwiftData

/// Repository for fetching lesson data from Supabase
class LessonRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientManager.shared.client) {
        self.client = client
    }

    // MARK: - Channel Methods

    /// Fetch all channels from Supabase
    func fetchAllChannels() async throws -> [ChannelDTO] {
        let response: [ChannelDTO] = try await client.database
            .from("channels")
            .select()
            .order("title", ascending: true)
            .execute()
            .value

        return response
    }

    /// Fetch channels for a specific language
    func fetchChannels(for language: String) async throws -> [ChannelDTO] {
        let response: [ChannelDTO] = try await client.database
            .from("channels")
            .select()
            .eq("language", value: language)
            .order("title", ascending: true)
            .execute()
            .value

        return response
    }

    /// Save channels to SwiftData
    func saveChannelsToSwiftData(_ channelDTOs: [ChannelDTO], modelContext: ModelContext) throws {
        for channelDTO in channelDTOs {
            // Check if channel already exists
            let descriptor = FetchDescriptor<Channel>(
                predicate: #Predicate { $0.id == channelDTO.id }
            )

            let existingChannels = try modelContext.fetch(descriptor)

            if existingChannels.isEmpty {
                // Create new channel
                let channel = Channel(
                    id: channelDTO.id,
                    title: channelDTO.title,
                    subtitle: channelDTO.subtitle ?? "",
                    description: channelDTO.description,
                    coverImageURL: channelDTO.cover_image_url,
                    iconName: channelDTO.icon_name,
                    language: channelDTO.language
                )

                modelContext.insert(channel)
            } else if let existingChannel = existingChannels.first {
                // Update existing channel with new fields
                existingChannel.title = channelDTO.title
                existingChannel.subtitle = channelDTO.subtitle ?? existingChannel.subtitle
                existingChannel.coverImageURL = channelDTO.cover_image_url
            }
        }

        try modelContext.save()
    }

    // MARK: - Lesson Methods

    /// Fetch all lessons from Supabase
    func fetchAllLessons() async throws -> [LessonDTO] {
        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .order("date", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch lessons for a specific language
    func fetchLessons(for language: String) async throws -> [LessonDTO] {
        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("language", value: language)
            .order("date", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch lessons for a specific channel
    func fetchLessons(for channelId: UUID) async throws -> [LessonDTO] {
        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("channel_id", value: channelId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch lessons for a specific date
    func fetchLessons(for date: Date) async throws -> [LessonDTO] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("date", value: dateString)
            .execute()
            .value

        return response
    }

    /// Fetch a single lesson by ID
    func fetchLesson(id: UUID) async throws -> LessonDTO {
        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        guard let lesson = response.first else {
            throw RepositoryError.lessonNotFound
        }

        return lesson
    }

    /// Fetch all sentences for a specific lesson
    func fetchSentences(for lessonId: UUID) async throws -> [SentenceDTO] {
        let response: [SentenceDTO] = try await client.database
            .from("sentences")
            .select()
            .eq("lesson_id", value: lessonId.uuidString)
            .order("order_index", ascending: true)
            .execute()
            .value

        return response
    }

    /// Fetch lesson with all its sentences
    func fetchLessonWithSentences(id: UUID) async throws -> (lesson: LessonDTO, sentences: [SentenceDTO]) {
        async let lessonTask = fetchLesson(id: id)
        async let sentencesTask = fetchSentences(for: id)

        let lesson = try await lessonTask
        let sentences = try await sentencesTask

        return (lesson, sentences)
    }

    /// Fetch related lessons (same content, different languages) by content_group_id
    func fetchRelatedLessons(for contentGroupId: UUID) async throws -> [LessonDTO] {
        let response: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("content_group_id", value: contentGroupId.uuidString)
            .order("language", ascending: true)
            .execute()
            .value

        return response
    }

    /// Fetch translation sentences for a lesson in a target language
    /// - Parameters:
    ///   - contentGroupId: The content group ID linking related lessons
    ///   - targetLanguage: The language code for the translation (e.g., "ja", "en", "fr")
    /// - Returns: Array of sentence texts in the target language, ordered by sentence index
    func fetchTranslationSentences(contentGroupId: UUID, targetLanguage: String) async throws -> [String] {
        // First, find the lesson in the target language
        let lessons: [LessonDTO] = try await client.database
            .from("lessons")
            .select()
            .eq("content_group_id", value: contentGroupId.uuidString)
            .eq("language", value: targetLanguage)
            .limit(1)
            .execute()
            .value

        guard let targetLesson = lessons.first else {
            throw RepositoryError.lessonNotFound
        }

        // Fetch sentences for that lesson
        let sentences = try await fetchSentences(for: targetLesson.id)

        // Return just the text, ordered by index
        return sentences.map { $0.text }
    }

    /// Save lessons and sentences to SwiftData
    func saveLessonsToSwiftData(_ lessonDTOs: [LessonDTO], sentences: [UUID: [SentenceDTO]], modelContext: ModelContext, channel: Channel) throws {
        for lessonDTO in lessonDTOs {
            // Check if lesson already exists
            let descriptor = FetchDescriptor<Lesson>(
                predicate: #Predicate { $0.id == lessonDTO.id }
            )

            let existingLessons = try modelContext.fetch(descriptor)

            if existingLessons.isEmpty {
                // Create new lesson
                let lesson = Lesson(
                    id: lessonDTO.id,
                    title: lessonDTO.title,
                    description: "", // No description in Supabase yet
                    date: lessonDTO.parsedDate,
                    sourceURL: lessonDTO.source_url,
                    language: lessonDTO.language,
                    contentGroupId: lessonDTO.content_group_id,
                    audioURL: lessonDTO.audio_url // NEW: Lesson-level audio URL
                )
                lesson.channel = channel

                // Add sentences with timestamps
                if let sentenceDTOs = sentences[lessonDTO.id] {
                    for sentenceDTO in sentenceDTOs {
                        let sentence = Sentence(
                            id: sentenceDTO.id,
                            text: sentenceDTO.text,
                            order: sentenceDTO.order_index,
                            estimatedDuration: sentenceDTO.durationInSeconds,
                            audioURL: sentenceDTO.audio_url, // Deprecated - kept for backward compatibility
                            startTime: sentenceDTO.startTimeInSeconds, // NEW
                            endTime: sentenceDTO.endTimeInSeconds // NEW
                        )
                        lesson.sentences.append(sentence)
                    }
                }

                modelContext.insert(lesson)
            }
        }

        try modelContext.save()
    }
}

// MARK: - Repository Errors

enum RepositoryError: Error, LocalizedError {
    case lessonNotFound
    case networkError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .lessonNotFound:
            return "Lesson not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}
