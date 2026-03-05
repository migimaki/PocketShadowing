//
//  SentencesScrollView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct SentencesScrollView: View {
    let sentences: [Sentence]
    let currentIndex: Int
    let isPlaying: Bool
    let recognizedTextBySentence: [Int: String]
    let currentRecognizedText: String
    let viewMode: PlayerViewModel.ViewMode
    let translationSentences: [String]

    @Namespace private var sentenceNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(Array(sentences.enumerated()), id: \.element.id) { index, sentence in
                        VStack(alignment: .leading, spacing: 8) {
                            // Display based on view mode
                            if viewMode != .shadowing {
                                // Always show original sentence
                                Text(sentence.text)
                                    .font(.system(size: 28))
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor(for: index))
                                    .id(index)

                                // Show translation below in translation mode
                                if viewMode == .translation, index < translationSentences.count {
                                    Text(translationSentences[index])
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }

                                // Recognized text with color-coded comparison (if available)
                                if let recognizedText = getRecognizedText(for: index), !recognizedText.isEmpty {
                                    RecognizedTextView(
                                        originalText: sentence.text,
                                        recognizedText: recognizedText
                                    )
                                }
                            } else {
                                // Shadowing mode: completely empty
                                Color.clear
                                    .frame(height: 100)
                                    .id(index)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 40)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.visible)
            .onChange(of: currentIndex) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onAppear {
                // Scroll to current sentence on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }

    private func textColor(for index: Int) -> Color {
        if index == currentIndex {
            return .appPrimary  // Light blue (#83D1FF) for current sentence
        } else if index < currentIndex {
            return .white       // White for past sentences
        } else {
            return .secondary   // Gray for future sentences
        }
    }

    private func getRecognizedText(for index: Int) -> String? {
        // If this is the current sentence, show live recognized text
        if index == currentIndex && !currentRecognizedText.isEmpty {
            return currentRecognizedText
        }
        // Otherwise show saved recognized text
        return recognizedTextBySentence[index]
    }
}

#Preview {
    let sentences = [
        Sentence(text: "Today, we're diving into a fascinating question: Can AI really create art?", order: 0),
        Sentence(text: "Yeah, that's a big one.", order: 1),
        Sentence(text: "Over the past few years, we've seen AI models like DALL-E, Midjourney, and Runway generating paintings, videos, even whole music albums.", order: 2),
        Sentence(text: "Some of these pieces have sold for thousands of dollars.", order: 3),
        Sentence(text: "But here's what's interesting: most AI art isn't created by AI alone.", order: 4),
    ]

    let recognizedTexts: [Int: String] = [
        0: "Today we're diving into a fascinating question can AI really create art",
        1: "Yeah that's a big one"
    ]

    return VStack {
        SentencesScrollView(
            sentences: sentences,
            currentIndex: 2,
            isPlaying: true,
            recognizedTextBySentence: recognizedTexts,
            currentRecognizedText: "Over the past few years we've seen AI models...",
            viewMode: .original,
            translationSentences: []
        )
    }
}
