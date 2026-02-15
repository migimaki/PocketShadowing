//
//  OnboardingView.swift
//  PocketShadowing
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var currentPage = 0
    @State private var isLoading = false

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "waveform.and.mic",
            "Listen & Shadow",
            "Listen to native English speakers and practice speaking along with them. Your voice is recognized in real-time to help you improve."
        ),
        (
            "chart.bar.fill",
            "Track Your Progress",
            "Get accuracy and speed scores for each practice session. Beat your best scores and watch your English improve over time."
        ),
        (
            "globe",
            "Learn Anywhere",
            "Practice English shadowing anytime, anywhere. Choose from a variety of channels and lessons to match your interests."
        )
    ]

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            description: pages[index].description
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom button area
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        Button {
                            Task {
                                await completeOnboarding()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                Text("Get Started")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(isLoading)
                    } else {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() async {
        isLoading = true
        let repository = ProfileRepository()
        let nativeLanguage = UserSettings.shared.nativeLanguage
        do {
            try await repository.upsertProfile(
                nativeLanguage: nativeLanguage,
                onboardingCompleted: true
            )
            authManager.completeOnboarding()
        } catch {
            print("Failed to save profile: \(error)")
            // Still let the user proceed even if profile save fails
            authManager.completeOnboarding()
        }
        isLoading = false
    }
}

// MARK: - Onboarding Page

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary)
                .padding(.bottom, 8)

            Text(title)
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
}
