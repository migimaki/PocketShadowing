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

            var wordString = AttributedString(wordPair.recognized)

            // Color based on match
            if wordPair.matches {
                wordString.foregroundColor = .green
            } else if wordPair.recognized == "---" {
                // Skipped word in original
                continue
            } else {
                wordString.foregroundColor = .red
            }

            result += wordString
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
    }

    private func alignWords(_ original: [String], _ recognized: [String]) -> [WordPair] {
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
                    // Found a match
                    // Skip any unmatched original words before this
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
