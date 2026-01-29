//
//  PlayerControlsView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI

struct PlayerControlsView: View {
    let isPlaying: Bool
    let canGoBack: Bool
    let canGoForward: Bool
    let onPlayPause: () -> Void
    let onRewind: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Rewind button
            Button(action: onRewind) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: AudioConstants.smallControlButtonSize, height: AudioConstants.smallControlButtonSize)
            }
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1.0 : 0.3)

            // Play/Pause button
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: AudioConstants.controlButtonSize))
                    .foregroundColor(.appPrimary)
            }

            // Forward button
            Button(action: onForward) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: AudioConstants.smallControlButtonSize, height: AudioConstants.smallControlButtonSize)
            }
            .disabled(!canGoForward)
            .opacity(canGoForward ? 1.0 : 0.3)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PlayerControlsView(
            isPlaying: false,
            canGoBack: true,
            canGoForward: true,
            onPlayPause: {},
            onRewind: {},
            onForward: {}
        )

        PlayerControlsView(
            isPlaying: true,
            canGoBack: false,
            canGoForward: false,
            onPlayPause: {},
            onRewind: {},
            onForward: {}
        )
    }
}
