//
//  LessonDataService.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import Foundation
import SwiftData

class LessonDataService {
    /// Load sample lesson data for "6 Minute English - AI and Art"
    static func loadSampleLesson(into context: ModelContext) {
        // Check if lessons already exist
        let descriptor = FetchDescriptor<Lesson>()
        if let existingLessons = try? context.fetch(descriptor), !existingLessons.isEmpty {
            print("Sample lessons already loaded")
            return
        }

        let lesson = Lesson(
            title: "6 Minute English",
            description: "AI and Art - Today, we're diving into a fascinating question: Can AI really create art?"
        )

        let sentenceTexts = [
            "Today, we're diving into a fascinating question: Can AI really create art?",
            "Yeah, that's a big one.",
            "Over the past few years, we've seen AI models like DALL-E, Midjourney, and Runway generating paintings, videos, even whole music albums.",
            "Some of these pieces have sold for thousands of dollars.",
            "But here's what's interesting: most AI art isn't created by AI alone.",
            "It's co-created.",
            "A human writes the prompt, chooses the best output, edits it — it's still a deeply human process.",
            "I like to think of it as a new kind of brush.",
            "Just like photography once changed how we create images, AI is now a tool for expression.",
            "So maybe the question isn't whether AI can make art, but whether we're ready to expand what we call art.",
            "That's a fascinating way to look at it.",
            "Thanks for joining us today. See you next time!"
        ]

        for (index, text) in sentenceTexts.enumerated() {
            let estimatedDuration = Sentence.estimateDuration(for: text)
            let sentence = Sentence(
                text: text,
                order: index,
                estimatedDuration: estimatedDuration
            )
            lesson.sentences.append(sentence)
        }

        // Create initial progress
        let progress = LessonProgress()
        lesson.progress = progress

        context.insert(lesson)

        do {
            try context.save()
            print("Sample lesson loaded successfully")
        } catch {
            print("Failed to save sample lesson: \(error)")
        }
    }

    /// Load sample lessons if needed (called from app startup)
    static func initializeSampleData(context: ModelContext) {
        loadSampleLesson(into: context)
    }
}
