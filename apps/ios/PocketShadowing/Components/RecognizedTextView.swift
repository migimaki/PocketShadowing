//
//  RecognizedTextView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct RecognizedTextView: View {
    let originalText: String
    let recognizedText: String

    var body: some View {
        let comparison = compareTexts(original: originalText, recognized: recognizedText)

        HStack(alignment: .top, spacing: 0) {
            Text(comparison)
                .font(.body)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func compareTexts(original: String, recognized: String) -> AttributedString {
        // Normalize and split texts into words
        let originalWords = normalizeText(original).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let recognizedWords = normalizeText(recognized).components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        var result = AttributedString()

        // Use dynamic programming for better word matching (handles insertions/deletions)
        let alignment = alignWords(originalWords, recognizedWords)

        for (index, wordPair) in alignment.enumerated() {
            if index > 0 {
                result += AttributedString(" ")
            }

            if wordPair.isMissing {
                // Missing original word shown in white 20% opacity
                var wordString = AttributedString(wordPair.original)
                wordString.foregroundColor = Color.white.opacity(0.2)
                result += wordString
            } else {
                var wordString = AttributedString(wordPair.recognized)
                wordString.foregroundColor = wordPair.matches ? .green : Color(red: 1.0, green: 0.502, blue: 0.322)
                result += wordString
            }
        }

        return result
    }

    private func normalizeText(_ text: String) -> String {
        // Remove punctuation and convert to lowercase for comparison
        return text.lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
    }

    private struct WordPair {
        let original: String
        let recognized: String
        let matches: Bool
        let isMissing: Bool
    }

    private func alignWords(_ original: [String], _ recognized: [String]) -> [WordPair] {
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

        // Backtrack to build interleaved alignment (in reverse)
        var reversed: [WordPair] = []
        var i = n, j = m
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && wordsMatch(original[i - 1], recognized[j - 1]) {
                reversed.append(WordPair(original: original[i - 1], recognized: recognized[j - 1], matches: true, isMissing: false))
                i -= 1
                j -= 1
            } else if i > 0 && (j == 0 || dp[i - 1][j] >= dp[i][j - 1]) {
                // Original word was skipped (missing from recognized)
                reversed.append(WordPair(original: original[i - 1], recognized: "", matches: false, isMissing: true))
                i -= 1
            } else {
                // Extra recognized word (not in original)
                reversed.append(WordPair(original: "", recognized: recognized[j - 1], matches: false, isMissing: false))
                j -= 1
            }
        }

        return reversed.reversed()
    }

    private func wordsMatch(_ word1: String, _ word2: String) -> Bool {
        // Simple equality check (could be enhanced with fuzzy matching)
        return word1 == word2
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Original:")
                .font(.caption)
            Text("Today, we're diving into a fascinating question: Can AI really create art?")
                .font(.body)

            Text("You said:")
                .font(.caption)
                .padding(.top, 8)
            RecognizedTextView(
                originalText: "Today, we're diving into a fascinating question: Can AI really create art?",
                recognizedText: "Today we're diving into a fascinating question can AI really create art"
            )
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
            Text("Original:")
                .font(.caption)
            Text("Yeah, that's a big one.")
                .font(.body)

            Text("You said:")
                .font(.caption)
                .padding(.top, 8)
            RecognizedTextView(
                originalText: "Yeah, that's a big one.",
                recognizedText: "Yeah that's a big one"
            )
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
            Text("Original:")
                .font(.caption)
            Text("Over the past few years, we've seen AI models generating art.")
                .font(.body)

            Text("You said:")
                .font(.caption)
                .padding(.top, 8)
            RecognizedTextView(
                originalText: "Over the past few years, we've seen AI models generating art.",
                recognizedText: "Over the past years we have seen AI models making art"
            )
        }
    }
    .padding()
}
