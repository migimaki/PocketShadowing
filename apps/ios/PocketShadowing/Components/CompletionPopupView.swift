//
//  CompletionPopupView.swift
//  WalkingTalking
//
//  Completion popup shown when user finishes all sentences
//

import SwiftUI

struct CompletionPopupView: View {
    @AppStorage("nativeLanguage") private var nativeLanguage: String = "en"
    let accuracyScore: Double
    let speedScore: Double
    let bestAccuracyScore: Double
    let bestSpeedScore: Double
    let onTryAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text(L10n.lessonComplete)
                .font(.title2)
                .fontWeight(.bold)

            // Circular gauges
            HStack(spacing: 40) {
                // Accuracy gauge
                VStack(spacing: 8) {
                    CircularGaugeView(
                        score: accuracyScore,
                        title: L10n.accuracy,
                        icon: "text.alignleft",
                        color: .blue
                    )

                    // Best accuracy (if exists and different)
                    if bestAccuracyScore > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(L10n.bestScore(Int(bestAccuracyScore.rounded())))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Speed gauge
                VStack(spacing: 8) {
                    CircularGaugeView(
                        score: speedScore,
                        title: L10n.speed,
                        icon: "timer",
                        color: .green
                    )

                    // Best speed (if exists and different)
                    if bestSpeedScore > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(L10n.bestScore(Int(bestSpeedScore.rounded())))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 16)

            // Buttons
            VStack(spacing: 12) {
                // Try Again button
                Button(action: onTryAgain) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.tryAgain)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }

                // Close button
                Button(action: onClose) {
                    Text(L10n.close)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0x5B / 255.0, green: 0x4E / 255.0, blue: 0x66 / 255.0))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color(red: 0x22 / 255.0, green: 0x0D / 255.0, blue: 0x34 / 255.0))
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(40)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        CompletionPopupView(
            accuracyScore: 85.0,
            speedScore: 92.0,
            bestAccuracyScore: 80.0,
            bestSpeedScore: 88.0,
            onTryAgain: { print("Try again") },
            onClose: { print("Close") }
        )
    }
}
