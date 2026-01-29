//
//  GradientBackground.swift
//  WalkingTalking
//
//  Beautiful custom background for the app
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Fallback color (dark blue) in case image doesn't load
            Color(red: 0.05, green: 0.05, blue: 0.15)

            // Custom background image
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
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
