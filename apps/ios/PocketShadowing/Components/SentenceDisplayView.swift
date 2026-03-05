//
//  SentenceDisplayView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct SentenceDisplayView: View {
    let sentence: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(sentence)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.3), value: isActive)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SentenceDisplayView(
            sentence: "Today, we're diving into a fascinating question: Can AI really create art?",
            isActive: false
        )

        SentenceDisplayView(
            sentence: "Over the past few years, we've seen AI models like DALL-E, Midjourney, and Runway generating paintings, videos, even whole music albums.",
            isActive: true
        )
    }
    .padding()
}
