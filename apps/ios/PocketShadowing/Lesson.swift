//
//  Lesson.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import Foundation
import SwiftData

@Model
final class Lesson {
    var id: UUID
    var title: String
    var lessonDescription: String
    var date: Date // Publication date from news article
    var sourceURL: String // Original article URL
    var createdDate: Date
    var language: String // Language code: en, ja, fr
    var contentGroupId: UUID? // Links lessons with same content in different languages
    var audioURL: String? // NEW: Lesson-level audio URL (single file for all sentences)

    @Relationship(deleteRule: .cascade)
    var sentences: [Sentence]

    @Relationship(deleteRule: .cascade)
    var progress: LessonProgress?

    @Relationship(inverse: \Channel.lessons)
    var channel: Channel?

    init(id: UUID = UUID(), title: String, description: String, date: Date = Date(), sourceURL: String = "", language: String = "en", contentGroupId: UUID? = nil, audioURL: String? = nil) {
        self.id = id
        self.title = title
        self.lessonDescription = description
        self.date = date
        self.sourceURL = sourceURL
        self.createdDate = Date()
        self.language = language
        self.contentGroupId = contentGroupId
        self.audioURL = audioURL
        self.sentences = []
    }

    var totalSentences: Int {
        sentences.count
    }

    var estimatedTotalDuration: TimeInterval {
        sentences.reduce(0.0) { $0 + $1.estimatedDuration }
    }

    // Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
