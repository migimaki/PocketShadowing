//
//  WalkingTalkingTests.swift
//  WalkingTalkingTests
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import XCTest
import AVFoundation
@testable import WalkingTalking

final class WalkingTalkingTests: XCTestCase {

    // MARK: - Sentence Tests

    func testSentenceEstimateDuration() throws {
        let shortText = "Hello world"
        let shortDuration = Sentence.estimateDuration(for: shortText)
        XCTAssertGreaterThanOrEqual(shortDuration, 2.0, "Minimum duration should be 2 seconds")

        let longText = "This is a much longer sentence with many more words that will take longer to speak"
        let longDuration = Sentence.estimateDuration(for: longText)
        XCTAssertGreaterThan(longDuration, shortDuration, "Longer text should have longer duration")
    }

    // MARK: - Lesson Tests

    func testLessonTotalSentences() throws {
        let lesson = Lesson(title: "Test", description: "Test lesson")
        XCTAssertEqual(lesson.totalSentences, 0)

        lesson.sentences.append(Sentence(text: "First", order: 0))
        lesson.sentences.append(Sentence(text: "Second", order: 1))

        XCTAssertEqual(lesson.totalSentences, 2)
    }

    func testLessonEstimatedTotalDuration() throws {
        let lesson = Lesson(title: "Test", description: "Test lesson")

        let sentence1 = Sentence(text: "First", order: 0, estimatedDuration: 3.0)
        let sentence2 = Sentence(text: "Second", order: 1, estimatedDuration: 4.0)

        lesson.sentences.append(sentence1)
        lesson.sentences.append(sentence2)

        XCTAssertEqual(lesson.estimatedTotalDuration, 7.0)
    }

    // MARK: - LessonProgress Tests

    func testLessonProgressUpdate() throws {
        let progress = LessonProgress()
        XCTAssertEqual(progress.currentSentenceIndex, 0)

        progress.updateProgress(currentIndex: 5)
        XCTAssertEqual(progress.currentSentenceIndex, 5)
    }

    func testLessonProgressMarkCompleted() throws {
        let progress = LessonProgress()
        XCTAssertEqual(progress.completedSentences, 0)

        progress.markSentenceCompleted()
        XCTAssertEqual(progress.completedSentences, 1)

        progress.markSentenceCompleted()
        XCTAssertEqual(progress.completedSentences, 2)
    }

    func testLessonProgressReset() throws {
        let progress = LessonProgress(currentSentenceIndex: 5)
        progress.completedSentences = 3

        progress.reset()

        XCTAssertEqual(progress.currentSentenceIndex, 0)
        XCTAssertEqual(progress.completedSentences, 0)
    }

    // MARK: - PlayerViewModel Tests

    func testPlayerViewModelInitialization() throws {
        let lesson = Lesson(title: "Test", description: "Test")
        lesson.sentences.append(Sentence(text: "First", order: 0))
        lesson.sentences.append(Sentence(text: "Second", order: 1))

        let viewModel = PlayerViewModel(lesson: lesson)

        XCTAssertEqual(viewModel.currentSentenceIndex, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.totalSentences, 2)
    }

    func testPlayerViewModelCurrentSentence() throws {
        let lesson = Lesson(title: "Test", description: "Test")
        let sentence1 = Sentence(text: "First", order: 0)
        let sentence2 = Sentence(text: "Second", order: 1)
        lesson.sentences.append(sentence1)
        lesson.sentences.append(sentence2)

        let viewModel = PlayerViewModel(lesson: lesson)

        XCTAssertEqual(viewModel.currentSentence?.text, "First")

        viewModel.currentSentenceIndex = 1
        XCTAssertEqual(viewModel.currentSentence?.text, "Second")
    }

    func testPlayerViewModelProgress() throws {
        let lesson = Lesson(title: "Test", description: "Test")
        lesson.sentences.append(Sentence(text: "1", order: 0))
        lesson.sentences.append(Sentence(text: "2", order: 1))
        lesson.sentences.append(Sentence(text: "3", order: 2))
        lesson.sentences.append(Sentence(text: "4", order: 3))

        let viewModel = PlayerViewModel(lesson: lesson)

        XCTAssertEqual(viewModel.currentProgress, 0.0)

        viewModel.currentSentenceIndex = 2
        XCTAssertEqual(viewModel.currentProgress, 0.5)

        viewModel.currentSentenceIndex = 4
        XCTAssertEqual(viewModel.currentProgress, 1.0)
    }

    func testPlayerViewModelNavigation() throws {
        let lesson = Lesson(title: "Test", description: "Test")
        lesson.sentences.append(Sentence(text: "1", order: 0))
        lesson.sentences.append(Sentence(text: "2", order: 1))
        lesson.sentences.append(Sentence(text: "3", order: 2))

        let viewModel = PlayerViewModel(lesson: lesson)

        // Initial state
        XCTAssertFalse(viewModel.canGoToPrevious)
        XCTAssertTrue(viewModel.canGoToNext)

        // Move to middle
        viewModel.currentSentenceIndex = 1
        XCTAssertTrue(viewModel.canGoToPrevious)
        XCTAssertTrue(viewModel.canGoToNext)

        // Move to end
        viewModel.currentSentenceIndex = 2
        XCTAssertTrue(viewModel.canGoToPrevious)
        XCTAssertFalse(viewModel.canGoToNext)
    }
}
