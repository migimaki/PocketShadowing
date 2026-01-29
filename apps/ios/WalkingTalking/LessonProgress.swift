//
//  LessonProgress.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import Foundation
import SwiftData

@Model
final class LessonProgress {
    var id: UUID
    var currentSentenceIndex: Int
    var completedSentences: Int
    var lastPlayedDate: Date
    var totalPracticeTime: TimeInterval

    // Best score tracking
    var bestAccuracyScore: Double
    var bestSpeedScore: Double
    var bestTotalScore: Double
    var bestScoreDate: Date?

    @Relationship(inverse: \Lesson.progress)
    var lesson: Lesson?

    init(id: UUID = UUID(), currentSentenceIndex: Int = 0) {
        self.id = id
        self.currentSentenceIndex = currentSentenceIndex
        self.completedSentences = 0
        self.lastPlayedDate = Date()
        self.totalPracticeTime = 0
        self.bestAccuracyScore = 0.0
        self.bestSpeedScore = 0.0
        self.bestTotalScore = 0.0
        self.bestScoreDate = nil
    }

    func updateProgress(currentIndex: Int) {
        self.currentSentenceIndex = currentIndex
        self.lastPlayedDate = Date()
    }

    func markSentenceCompleted() {
        self.completedSentences += 1
    }

    func reset() {
        self.currentSentenceIndex = 0
        self.completedSentences = 0
        self.lastPlayedDate = Date()
    }

    func updateBestScore(accuracyScore: Double, speedScore: Double) {
        var updated = false

        // Update best accuracy if current is better
        if accuracyScore > self.bestAccuracyScore {
            self.bestAccuracyScore = accuracyScore
            updated = true
        }

        // Update best speed if current is better
        if speedScore > self.bestSpeedScore {
            self.bestSpeedScore = speedScore
            updated = true
        }

        // Update total and date if either improved
        if updated {
            self.bestTotalScore = self.bestAccuracyScore + self.bestSpeedScore
            self.bestScoreDate = Date()
        }
    }
}
