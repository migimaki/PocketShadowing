//
//  CompletionPopupView.swift
//  WalkingTalking
//
//  Completion popup shown when user finishes all sentences
//

import SwiftUI

struct CompletionPopupView: View {
    let accuracyScore: Double
    let speedScore: Double
    let bestAccuracyScore: Double
    let bestSpeedScore: Double
    let onTryAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Lesson Complete!")
                .font(.title2)
                .fontWeight(.bold)

            // Circular gauges
            HStack(spacing: 40) {
                // Accuracy gauge
                VStack(spacing: 8) {
                    CircularGaugeView(
                        score: accuracyScore,
                        title: "Accuracy",
                        icon: "text.alignleft",
                        color: .blue
                    )

                    // Best accuracy (if exists and different)
                    if bestAccuracyScore > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("Best: \(Int(bestAccuracyScore.rounded()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Speed gauge
                VStack(spacing: 8) {
                    CircularGaugeView(
                        score: speedScore,
                        title: "Speed",
                        icon: "timer",
                        color: .green
                    )

                    // Best speed (if exists and different)
                    if bestSpeedScore > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("Best: \(Int(bestSpeedScore.rounded()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 16)

            // New best score indicator
            if accuracyScore >= bestAccuracyScore || speedScore >= bestSpeedScore {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("New Best Score!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(8)
            }

            // Buttons
            VStack(spacing: 12) {
                // Try Again button
                Button(action: onTryAgain) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Close button
                Button(action: onClose) {
                    Text("Close")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
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
