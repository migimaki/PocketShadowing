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
        let n = original.count
        let m = recognized.count

        guard n > 0, m > 0 else { return [] }

        // Build LCS DP table
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 1...n {
            for j in 1...m {
                if wordsMatch(original[i - 1], recognized[j - 1]) {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        // Backtrack to find which recognized words are LCS matches
        var matchedRecIndices = Set<Int>()
        var i = n, j = m
        while i > 0 && j > 0 {
            if wordsMatch(original[i - 1], recognized[j - 1]) {
                matchedRecIndices.insert(j - 1)
                i -= 1
                j -= 1
            } else if dp[i - 1][j] > dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }

        // Build result: each recognized word is either a match or mismatch
        var result: [WordPair] = []
        for idx in 0..<m {
            let isMatch = matchedRecIndices.contains(idx)
            result.append(WordPair(
                original: isMatch ? recognized[idx] : "",
                recognized: recognized[idx],
                matches: isMatch
            ))
        }

        return result
    }

    private static func wordsMatch(_ word1: String, _ word2: String) -> Bool {
        return word1 == word2
    }
}
