//
//  SupabaseModels.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation

// MARK: - DTOs for Supabase API responses

/// Channel data from Supabase
struct ChannelDTO: Codable {
    let id: UUID
    let title: String
    let subtitle: String?
    let description: String
    let cover_image_url: String?
    let icon_name: String
    let language: String
    let created_at: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, language, created_at
        case cover_image_url
        case icon_name
    }
}

/// Lesson data from Supabase
struct LessonDTO: Codable {
    let id: UUID
    let title: String
    let source_url: String
    let date: String // "YYYY-MM-DD" format
    let language: String
    let channel_id: UUID
    let content_group_id: UUID?
    let audio_url: String? // NEW: Lesson-level audio URL (single file for all sentences)
    let created_at: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, language, created_at
        case source_url
        case channel_id
        case content_group_id
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
    let audio_url: String // Deprecated - use lesson.audio_url instead
    let duration: Int // Duration in seconds
    let start_time: Double? // NEW: Start timestamp in lesson audio file
    let end_time: Double? // NEW: End timestamp in lesson audio file

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

/// Combined lesson with sentences
struct LessonWithSentences: Codable {
    let lesson: LessonDTO
    let sentences: [SentenceDTO]
}
