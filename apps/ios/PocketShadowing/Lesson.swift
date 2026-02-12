//
//  Lesson.swift
//  PocketShadowing
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
    var date: Date
    var sourceURL: String
    var createdDate: Date
    var audioURL: String?

    @Relationship(deleteRule: .cascade)
    var sentences: [Sentence]

    @Relationship(deleteRule: .cascade)
    var progress: LessonProgress?

    @Relationship(inverse: \Channel.lessons)
    var channel: Channel?

    init(id: UUID = UUID(), title: String, description: String, date: Date = Date(), sourceURL: String = "", audioURL: String? = nil) {
        self.id = id
        self.title = title
        self.lessonDescription = description
        self.date = date
        self.sourceURL = sourceURL
        self.createdDate = Date()
        self.audioURL = audioURL
        self.sentences = []
    }

    var totalSentences: Int {
        sentences.count
    }

    var estimatedTotalDuration: TimeInterval {
        sentences.reduce(0.0) { $0 + $1.estimatedDuration }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
