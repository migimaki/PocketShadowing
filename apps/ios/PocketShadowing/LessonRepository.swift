//
//  LessonRepository.swift
//  PocketShadowing
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

    /// Save channels to SwiftData
    func saveChannelsToSwiftData(_ channelDTOs: [ChannelDTO], modelContext: ModelContext) throws {
        for channelDTO in channelDTOs {
            let descriptor = FetchDescriptor<Channel>(
                predicate: #Predicate { $0.id == channelDTO.id }
            )

            let existingChannels = try modelContext.fetch(descriptor)

            if existingChannels.isEmpty {
                let channel = Channel(
                    id: channelDTO.id,
                    title: channelDTO.title,
                    subtitle: channelDTO.subtitle ?? "",
                    description: channelDTO.description,
                    coverImageURL: channelDTO.cover_image_url,
                    iconName: channelDTO.icon_name,
                    genre: channelDTO.genre ?? "Beginner"
                )

                modelContext.insert(channel)
            } else if let existingChannel = existingChannels.first {
                existingChannel.title = channelDTO.title
                existingChannel.subtitle = channelDTO.subtitle ?? existingChannel.subtitle
                existingChannel.coverImageURL = channelDTO.cover_image_url
                existingChannel.genre = channelDTO.genre ?? existingChannel.genre
            }
        }

        try modelContext.save()
    }

    // MARK: - Follow Methods

    /// Fetch channel follows for the current user, ordered by newest first
    func fetchFollowedChannels() async throws -> [UserChannelFollowDTO] {
        guard let userId = client.auth.currentUser?.id else { return [] }

        let response: [UserChannelFollowDTO] = try await client.database
            .from("user_channel_follows")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Follow a channel for the current user
    func followChannel(channelId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        let dto = UserChannelFollowInsertDTO(user_id: userId, channel_id: channelId)

        try await client.database
            .from("user_channel_follows")
            .insert(dto)
            .execute()
    }

    /// Unfollow a channel for the current user
    func unfollowChannel(channelId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        try await client.database
            .from("user_channel_follows")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("channel_id", value: channelId.uuidString)
            .execute()
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

    /// Fetch translation sentences for a lesson in a target language
    /// Queries the sentence_translations table directly
    func fetchTranslationSentences(lessonId: UUID, targetLanguage: String) async throws -> [String] {
        // Get sentences for this lesson (to know the order)
        let sentences = try await fetchSentences(for: lessonId)
        let sentenceIds = sentences.map { $0.id.uuidString }

        guard !sentenceIds.isEmpty else {
            return []
        }

        // Query sentence_translations for these sentences in the target language
        let translations: [SentenceTranslationDTO] = try await client.database
            .from("sentence_translations")
            .select()
            .in("sentence_id", values: sentenceIds)
            .eq("language", value: targetLanguage)
            .execute()
            .value

        // Build a map of sentence_id -> translated text
        let translationMap = Dictionary(uniqueKeysWithValues: translations.map { ($0.sentence_id, $0.text) })

        // Return translations in sentence order
        return sentences.compactMap { translationMap[$0.id] }
    }

    /// Save lessons and sentences to SwiftData
    func saveLessonsToSwiftData(_ lessonDTOs: [LessonDTO], sentences: [UUID: [SentenceDTO]], modelContext: ModelContext, channel: Channel) throws {
        for lessonDTO in lessonDTOs {
            let descriptor = FetchDescriptor<Lesson>(
                predicate: #Predicate { $0.id == lessonDTO.id }
            )

            let existingLessons = try modelContext.fetch(descriptor)

            if existingLessons.isEmpty {
                let lesson = Lesson(
                    id: lessonDTO.id,
                    title: lessonDTO.title,
                    description: "",
                    date: lessonDTO.parsedDate,
                    sourceURL: lessonDTO.source_url,
                    audioURL: lessonDTO.audio_url
                )
                lesson.channel = channel

                if let sentenceDTOs = sentences[lessonDTO.id] {
                    for sentenceDTO in sentenceDTOs {
                        let sentence = Sentence(
                            id: sentenceDTO.id,
                            text: sentenceDTO.text,
                            order: sentenceDTO.order_index,
                            estimatedDuration: sentenceDTO.durationInSeconds,
                            audioURL: sentenceDTO.audio_url,
                            startTime: sentenceDTO.startTimeInSeconds,
                            endTime: sentenceDTO.endTimeInSeconds
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
