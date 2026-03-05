//
//  ScoreDisplayView.swift
//  WalkingTalking
//
//  Score display showing current session scores with circular gauges
//

import SwiftUI

struct ScoreDisplayView: View {
    let accuracyScore: Double      // Current accuracy: 0-100
    let speedScore: Double          // Current speed: 0-100
    let bestAccuracyScore: Double   // Best accuracy: 0-100
    let bestSpeedScore: Double      // Best speed: 0-100

    var body: some View {
        VStack(spacing: 12) {
            // Circular gauges
            HStack(spacing: 40) {
                // Accuracy gauge
                VStack(spacing: 4) {
                    CircularGaugeView(
                        score: accuracyScore,
                        title: "Accuracy",
                        icon: "text.alignleft",
                        color: .blue
                    )

                    // Best accuracy (if exists)
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
                VStack(spacing: 4) {
                    CircularGaugeView(
                        score: speedScore,
                        title: "Speed",
                        icon: "timer",
                        color: .green
                    )

                    // Best speed (if exists)
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
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    VStack(spacing: 20) {
        // High scores
        ScoreDisplayView(
            accuracyScore: 85.0,
            speedScore: 92.0,
            bestAccuracyScore: 90.0,
            bestSpeedScore: 95.0
        )

        Divider()

        // Medium scores
        ScoreDisplayView(
            accuracyScore: 65.0,
            speedScore: 70.0,
            bestAccuracyScore: 75.0,
            bestSpeedScore: 80.0
        )

        Divider()

        // Low scores
        ScoreDisplayView(
            accuracyScore: 45.0,
            speedScore: 38.0,
            bestAccuracyScore: 60.0,
            bestSpeedScore: 55.0
        )

        Divider()

        // No best score yet
        ScoreDisplayView(
            accuracyScore: 78.0,
            speedScore: 82.0,
            bestAccuracyScore: 0,
            bestSpeedScore: 0
        )
    }
    .padding()
}
