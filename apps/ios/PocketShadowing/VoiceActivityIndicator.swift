//
//  VoiceActivityIndicator.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct VoiceActivityIndicator: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(isActive ? .red : .gray)
                .font(.title3)

            Text(isActive ? "Speaking..." : "Listening...")
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)

            // Animated pulse
            if isActive {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isActive ? 1.2 : 0.8)
                    .opacity(isActive ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        VoiceActivityIndicator(isActive: false)
        VoiceActivityIndicator(isActive: true)
    }
}
