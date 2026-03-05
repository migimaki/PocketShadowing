//
//  ProgressBarView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let currentSentence: Int
    let totalSentences: Int

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: AudioConstants.minProgressBarHeight)
                        .cornerRadius(2)

                    // Progress
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: AudioConstants.minProgressBarHeight)
                        .cornerRadius(2)
                }
            }
            .frame(height: AudioConstants.minProgressBarHeight)

            // Time display
            HStack {
                Text("\(currentSentence)/\(totalSentences)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatProgress())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatProgress() -> String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(progress: 0.0, currentSentence: 1, totalSentences: 12)
            .padding()

        ProgressBarView(progress: 0.33, currentSentence: 4, totalSentences: 12)
            .padding()

        ProgressBarView(progress: 0.75, currentSentence: 9, totalSentences: 12)
            .padding()

        ProgressBarView(progress: 1.0, currentSentence: 12, totalSentences: 12)
            .padding()
    }
}
