//
//  ViewModeToggleButton.swift
//  WalkingTalking
//
//  View mode toggle button for player view
//

import SwiftUI

struct ViewModeToggleButton: View {
    let viewMode: PlayerViewModel.ViewMode
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch viewMode {
        case .original:
            return "icon_original"
        case .translation:
            return "icon_translation"
        case .shadowing:
            return "icon_shadowing"
        }
    }

    private var label: String {
        switch viewMode {
        case .original:
            return "Original"
        case .translation:
            return "Translation"
        case .shadowing:
            return "Shadow"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ViewModeToggleButton(viewMode: .original) {}
        ViewModeToggleButton(viewMode: .translation) {}
        ViewModeToggleButton(viewMode: .shadowing) {}
    }
    .padding()
}
