//
//  SupabaseModels.swift
//  PocketShadowing
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation

// MARK: - DTOs for Supabase API responses

/// Channel data from Supabase (English only, no language field)
struct ChannelDTO: Codable {
    let id: UUID
    let title: String
    let subtitle: String?
    let description: String
    let cover_image_url: String?
    let icon_name: String
    let created_at: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, created_at
        case cover_image_url
        case icon_name
    }
}

/// Lesson data from Supabase (English only, no language or content_group_id)
struct LessonDTO: Codable {
    let id: UUID
    let title: String
    let source_url: String
    let date: String // "YYYY-MM-DD" format
    let channel_id: UUID
    let audio_url: String?
    let created_at: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, created_at
        case source_url
        case channel_id
        case audio_url
    }

    var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
}

/// Sentence data from Supabase
struct SentenceDTO: Codable {
    let id: UUID
    let lesson_id: UUID
    let order_index: Int
    let text: String
    let audio_url: String
    let duration: Int
    let start_time: Double?
    let end_time: Double?

    enum CodingKeys: String, CodingKey {
        case id, text, duration
        case lesson_id
        case order_index
        case audio_url
        case start_time
        case end_time
    }

    var durationInSeconds: TimeInterval {
        TimeInterval(duration)
    }

    var startTimeInSeconds: TimeInterval {
        start_time ?? 0
    }

    var endTimeInSeconds: TimeInterval {
        end_time ?? TimeInterval(duration)
    }
}

/// Sentence translation data from Supabase
struct SentenceTranslationDTO: Codable {
    let id: UUID
    let sentence_id: UUID
    let language: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case id, language, text
        case sentence_id
    }
}

/// Lesson translation data from Supabase
struct LessonTranslationDTO: Codable {
    let id: UUID
    let lesson_id: UUID
    let language: String
    let title: String

    enum CodingKeys: String, CodingKey {
        case id, language, title
        case lesson_id
    }
}

/// Combined lesson with sentences
struct LessonWithSentences: Codable {
    let lesson: LessonDTO
    let sentences: [SentenceDTO]
}
