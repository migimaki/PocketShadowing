//
//  OnboardingView.swift
//  PocketShadowing
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var currentStep = 1
    @State private var isLoading = false
    @State private var practiceManager = OnboardingPracticeManager()

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Step indicator
                StepIndicator(currentStep: currentStep, totalSteps: 3)
                    .padding(.top, 16)

                // Step content
                Group {
                    switch currentStep {
                    case 1:
                        headphoneStep
                    case 2:
                        tryShadowingStep
                    case 3:
                        readyStep
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .onChange(of: currentStep) { oldValue, newValue in
            if oldValue == 2 && newValue != 2 {
                practiceManager.cleanup()
            }
        }
    }

    // MARK: - Step 1: Headphones

    private var headphoneStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary)
                .padding(.bottom, 8)

            Text("🎧 " + L10n.onboardingHeadphoneTitle)
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(L10n.onboardingHeadphoneMain)
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(L10n.onboardingHeadphoneSub)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()

            // Button
            Button {
                withAnimation {
                    currentStep = 2
                }
            } label: {
                Text(L10n.onboardingHeadphoneButton)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Step 2: Try Shadowing

    private var tryShadowingStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("🎤 " + L10n.onboardingTryShadowingTitle)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(L10n.onboardingTryShadowingMain)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(L10n.onboardingTryShadowingSub)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 24)

            Spacer()

            // Reference text card
            VStack(alignment: .leading, spacing: 12) {
                Text(practiceManager.referenceText)
                    .font(.system(size: 28))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)

                if !practiceManager.recognizedText.isEmpty {
                    RecognizedTextView(
                        originalText: practiceManager.referenceText,
                        recognizedText: practiceManager.recognizedText
                    )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            // Controls
            HStack(spacing: 32) {
                if practiceManager.hasFinishedOnce {
                    Button {
                        practiceManager.replay()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }

                Button {
                    if practiceManager.practiceState == .idle || practiceManager.practiceState == .finished {
                        practiceManager.startPractice()
                    }
                } label: {
                    Image(systemName: practiceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.bottom, 8)

            // Error message
            if let error = practiceManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Next button (appears after completing practice)
            if practiceManager.hasFinishedOnce {
                Button {
                    withAnimation {
                        currentStep = 3
                    }
                } label: {
                    Text(L10n.next)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 50)
        }
        .onAppear {
            practiceManager.setup()
        }
    }

    // MARK: - Step 3: Ready

    private var readyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "paperplane.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary)
                .padding(.bottom, 8)

            Text("🚀 " + L10n.onboardingReadyTitle)
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(L10n.onboardingReadyMain)
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(L10n.onboardingReadySub)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()

            // Button
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
                    Text(L10n.startLearning)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isLoading)
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Complete Onboarding

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
            authManager.completeOnboarding()
        }
        isLoading = false
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step == currentStep ? Color.appPrimary : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
}
