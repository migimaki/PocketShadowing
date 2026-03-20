//
//  PlayerView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI
import SwiftData

struct PlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: PlayerViewModel
    @State private var showSettings = false
    @State private var showCompletionPopup = false
    @State private var isLocked = false

    init(lesson: Lesson) {
        _viewModel = State(initialValue: PlayerViewModel(lesson: lesson))
    }

    var body: some View {
        ZStack {
            // Background layer
            GradientBackground()

            // Content layer
            VStack(spacing: 0) {
                // Lesson description (if available)
                if !viewModel.lesson.lessonDescription.isEmpty {
                    Text(viewModel.lesson.lessonDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }

                // All sentences in scrollable panel with inline recognized text
                if !viewModel.lesson.sentences.isEmpty {
                    SentencesScrollView(
                        sentences: viewModel.lesson.sentences.sorted(by: { $0.order < $1.order }),
                        currentIndex: viewModel.currentSentenceIndex,
                        isPlaying: viewModel.isPlaying,
                        recognizedTextBySentence: viewModel.recognizedTextBySentence,
                        currentRecognizedText: viewModel.recognizedText,
                        viewMode: viewModel.viewMode,
                        translationSentences: viewModel.translationSentences
                    )
                } else {
                    Spacer()
                    Text(L10n.noSentencesAvailable)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Bottom controls area
                VStack(spacing: 0) {
                // Discrete border
                Divider()
                    .background(Color.gray.opacity(0.3))

                if isLocked {
                    // Show slide to unlock when locked
                    SlideToUnlockView {
                        isLocked = false
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                } else {
                    // Show normal controls when unlocked
                    HStack(spacing: 16) {
                        // View mode toggle button on the left
                        ViewModeToggleButton(
                            viewMode: viewModel.viewMode,
                            onToggle: { viewModel.toggleViewMode() }
                        )

                        // Player controls in the center
                        PlayerControlsView(
                            isPlaying: viewModel.isPlaying,
                            isCompleted: viewModel.isCompleted,
                            canGoBack: viewModel.canGoToPrevious,
                            canGoForward: viewModel.canGoToNext,
                            onPlayPause: {
                                if viewModel.isCompleted {
                                    viewModel.restart()
                                } else {
                                    viewModel.togglePlayPause()
                                }
                            },
                            onRewind: { viewModel.goToPreviousSentence() },
                            onForward: { viewModel.goToNextSentence() }
                        )

                        // Lock button on the right
                        Button(action: {
                            isLocked = true
                        }) {
                            Image("icon_lock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            }
        }
        .navigationTitle(viewModel.lesson.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(isLocked)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .disabled(isLocked)
            }
        }
        .overlay {
            if showCompletionPopup {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Dismiss on background tap
                            showCompletionPopup = false
                        }

                    CompletionPopupView(
                        accuracyScore: viewModel.currentAccuracyScore,
                        speedScore: viewModel.currentSpeedScore,
                        bestAccuracyScore: viewModel.bestAccuracyScore,
                        bestSpeedScore: viewModel.bestSpeedScore,
                        onTryAgain: {
                            showCompletionPopup = false
                            viewModel.restart()
                        },
                        onClose: {
                            showCompletionPopup = false
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            PlayerSettingsView()
        }
        .onAppear {
            viewModel.setup()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted && !UserSettings.shared.isLoopEnabled {
                showCompletionPopup = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                print("[PlayerView] App entered background - ensuring recording continues")
                viewModel.handleBackground()
            case .inactive:
                print("[PlayerView] App became inactive")
            case .active:
                print("[PlayerView] App became active - resuming foreground")
                viewModel.handleForeground()
            @unknown default:
                break
            }
        }
        .alert(L10n.error, isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(L10n.ok) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Player Settings View

struct PlayerSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                List {
                    Section {
                        Toggle(L10n.loop, isOn: Binding(
                            get: { UserSettings.shared.isLoopEnabled },
                            set: { UserSettings.shared.isLoopEnabled = $0 }
                        ))
                        .listRowBackground(Color(red: 0x22/255, green: 0x0D/255, blue: 0x34/255))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Lesson.self, configurations: config)

    // Create sample lesson
    let lesson = Lesson(
        title: "6 Minute English",
        description: "AI and Art"
    )

    let sentences = [
        "Today, we're diving into a fascinating question: Can AI really create art?",
        "Yeah, that's a big one.",
        "Over the past few years, we've seen AI models generating art.",
        "Some pieces have sold for thousands of dollars."
    ]

    for (index, text) in sentences.enumerated() {
        let sentence = Sentence(text: text, order: index)
        lesson.sentences.append(sentence)
    }

    container.mainContext.insert(lesson)

    return NavigationStack {
        PlayerView(lesson: lesson)
    }
    .modelContainer(container)
}
