//
//  ScoringService.swift
//  WalkingTalking
//
//  Handles scoring calculations for accuracy and speed
//
//  Scoring System:
//  - Total points per lesson: 100pt
//  - Each sentence is worth: 10pt / number of sentences
//  - Per sentence: 50% accuracy + 50% speed
//
//  Accuracy: Based on word match percentage (0.0 to 1.0)
//  Speed: Linear decay from 2.0s (100%) to 10.0s (0%)
//

import Foundation

class ScoringService {

    // MARK: - Accuracy Calculation

    /// Calculate accuracy score based on word matching
    /// - Parameters:
    ///   - originalText: The original sentence text
    ///   - recognizedText: The user's recognized speech text
    /// - Returns: Accuracy percentage from 0.0 to 1.0
    static func calculateAccuracy(originalText: String, recognizedText: String) -> Double {
        // Normalize and split texts into words
        let originalWords = normalizeText(originalText).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let recognizedWords = normalizeText(recognizedText).components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Handle edge cases
        guard !originalWords.isEmpty else { return 0.0 }
        guard !recognizedWords.isEmpty else { return 0.0 }

        // Use word alignment to count matches
        let alignment = alignWords(originalWords, recognizedWords)
        let matchCount = alignment.filter { $0.matches }.count

        // Calculate accuracy as percentage of original words matched
        return Double(matchCount) / Double(originalWords.count)
    }

    // MARK: - Speed Calculation

    /// Calculate speed score based on total completion time
    /// - Parameter totalTime: Time from audio end to when user finishes (in seconds)
    /// - Returns: Speed score from 0.0 to 1.0
    static func calculateSpeed(totalTime: TimeInterval) -> Double {
        // Perfect score at 2.0s or less
        // Linear decay to 0% at 10.0s or more
        let minTime = 2.0
        let maxTime = 10.0

        if totalTime <= minTime {
            return 1.0
        } else if totalTime >= maxTime {
            return 0.0
        } else {
            return max(0.0, 1.0 - (totalTime - minTime) / (maxTime - minTime))
        }
    }

    // MARK: - Per-Sentence Score Calculation

    /// Calculate combined score for a single sentence
    /// - Parameters:
    ///   - originalText: The original sentence text
    ///   - recognizedText: The user's recognized speech text
    ///   - totalTime: Time from audio end to when user finishes
    ///   - pointsPerSentence: Maximum points for this sentence (e.g., 100/27 = 3.7)
    /// - Returns: Tuple of (accuracyPoints, speedPoints) - each can be 0 to pointsPerSentence
    static func calculateSentenceScore(
        originalText: String,
        recognizedText: String,
        totalTime: TimeInterval,
        pointsPerSentence: Double
    ) -> (accuracy: Double, speed: Double) {
        let accuracyPercentage = calculateAccuracy(originalText: originalText, recognizedText: recognizedText)
        let speedPercentage = calculateSpeed(totalTime: totalTime)

        // Calculate accuracy points
        let accuracyPoints = accuracyPercentage * pointsPerSentence

        // Speed points require minimum accuracy threshold (30%)
        // This prevents getting speed points for staying silent or speaking gibberish
        let speedPoints: Double
        if accuracyPercentage < 0.3 {
            // Accuracy too low - user didn't really try shadowing
            speedPoints = 0.0
        } else {
            // Accuracy acceptable - award speed points based on timing
            speedPoints = speedPercentage * pointsPerSentence
        }

        return (accuracyPoints, speedPoints)
    }

    // MARK: - Private Helper Methods

    private static func normalizeText(_ text: String) -> String {
        // Remove punctuation and convert to lowercase for comparison
        return text.lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
    }

    private struct WordPair {
        let original: String
        let recognized: String
        let matches: Bool
    }

    private static func alignWords(_ original: [String], _ recognized: [String]) -> [WordPair] {
        var result: [WordPair] = []
        var origIndex = 0
        var recIndex = 0

        while recIndex < recognized.count {
            let recWord = recognized[recIndex]

            // Try to find matching word in remaining original words (look ahead up to 3 words)
            var foundMatch = false
            for lookAhead in 0..<min(3, original.count - origIndex) {
                let origWord = original[origIndex + lookAhead]

                if wordsMatch(origWord, recWord) {
                    // Found a match - skip any unmatched original words before this
                    origIndex += lookAhead

                    result.append(WordPair(
                        original: origWord,
                        recognized: recWord,
                        matches: true
                    ))
                    origIndex += 1
                    recIndex += 1
                    foundMatch = true
                    break
                }
            }

            if !foundMatch {
                // No match found - mark as incorrect
                let origWord = origIndex < original.count ? original[origIndex] : ""
                result.append(WordPair(
                    original: origWord,
                    recognized: recWord,
                    matches: false
                ))

                // Only advance original if we have words left
                if origIndex < original.count {
                    origIndex += 1
                }
                recIndex += 1
            }
        }

        return result
    }

    private static func wordsMatch(_ word1: String, _ word2: String) -> Bool {
        return word1 == word2
    }
}
