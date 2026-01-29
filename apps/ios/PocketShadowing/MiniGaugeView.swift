//
//  MiniGaugeView.swift
//  WalkingTalking
//
//  Minimal circular gauge for navigation bar display
//  Just the circular arc with no text, icon, or numbers
//

import SwiftUI

struct MiniGaugeView: View {
    let score: Double  // 0-100
    let color: Color

    private var normalizedScore: Double {
        min(max(score, 0), 100) / 100.0
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .frame(width: 24, height: 24)

            // Progress arc
            Circle()
                .trim(from: 0, to: normalizedScore)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: normalizedScore)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        MiniGaugeView(score: 75, color: .blue)
        MiniGaugeView(score: 85, color: .green)
    }
    .padding()
}
