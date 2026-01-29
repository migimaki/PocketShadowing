//
//  CircularGaugeView.swift
//  WalkingTalking
//
//  Circular gauge component that displays a score from 0-100 like a speedometer
//

import SwiftUI

struct CircularGaugeView: View {
    let score: Double  // 0-100
    let title: String
    let icon: String
    let color: Color

    private var normalizedScore: Double {
        min(max(score, 0), 100) / 100.0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                // Progress arc
                Circle()
                    .trim(from: 0, to: normalizedScore)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: normalizedScore)

                // Center content
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)

                    Text("\(Int(score.rounded()))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        CircularGaugeView(
            score: 75,
            title: "Accuracy",
            icon: "text.alignleft",
            color: .blue
        )

        CircularGaugeView(
            score: 85,
            title: "Speed",
            icon: "timer",
            color: .green
        )
    }
    .padding()
}
