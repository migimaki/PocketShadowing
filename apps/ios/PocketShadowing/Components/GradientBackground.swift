//
//  GradientBackground.swift
//  WalkingTalking
//
//  Beautiful custom background for the app
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0x46 / 255.0, green: 0x67 / 255.0, blue: 0xA8 / 255.0),
                Color(red: 0x5A / 255.0, green: 0x48 / 255.0, blue: 0x99 / 255.0),
                Color(red: 0x3B / 255.0, green: 0x29 / 255.0, blue: 0x59 / 255.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - View Extension for Easy Application

extension View {
    /// Applies the app's signature gradient background
    func gradientBackground() -> some View {
        self.modifier(GradientBackgroundModifier())
    }
}

// MARK: - ViewModifier

struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GradientBackground()
            content
        }
    }
}

#Preview {
    VStack {
        Text("Sample Text")
            .font(.title)
            .foregroundColor(.white)
    }
    .gradientBackground()
}
