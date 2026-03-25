//
//  OnboardingPracticeManager.swift
//  PocketShadowing
//

import Foundation
import AVFoundation
import UIKit

@Observable
class OnboardingPracticeManager {
    // Services
    private let audioPlayerService = AudioPlayerService()
    private var recordingService = AudioRecordingService()
    private let speechRecognitionService = SpeechRecognitionService(languageCode: "en")
    private let audioSessionManager = AudioSessionManager.shared

    // Speech timeout
    private var listeningTimer: DispatchWorkItem?

    // State
    var recognizedText: String = ""
    var isPlaying: Bool = false
    var hasFinishedOnce: Bool = false
    var errorMessage: String?
    var hasMicrophonePermission: Bool = false
    var hasSpeechRecognitionPermission: Bool = false

    let referenceText = "What did you do today?"

    enum PracticeState {
        case idle
        case playing
        case listening
        case finished
    }
    var practiceState: PracticeState = .idle

    init() {
        setupDelegates()
    }

    private func setupDelegates() {
        audioPlayerService.delegate = self
        recordingService.delegate = self
        speechRecognitionService.delegate = self
    }

    // MARK: - Lifecycle

    func setup() {
        recordingService.requestMicrophonePermission { [weak self] granted in
            self?.hasMicrophonePermission = granted
        }
        speechRecognitionService.requestAuthorization { [weak self] granted in
            self?.hasSpeechRecognitionPermission = granted
        }
    }

    func cleanup() {
        cancelListeningTimer()
        audioPlayerService.stop()
        if recordingService.isRecording {
            recordingService.stopRecording()
        }
        speechRecognitionService.stopRecognition()
        audioSessionManager.deactivate()
        isPlaying = false
        practiceState = .idle
    }

    // MARK: - Practice Controls

    func startPractice() {
        guard practiceState == .idle || practiceState == .finished else { return }

        guard hasMicrophonePermission else {
            errorMessage = "Microphone access is required. Please enable it in Settings."
            return
        }
        guard hasSpeechRecognitionPermission else {
            errorMessage = "Speech recognition is required. Please enable it in Settings."
            return
        }

        recognizedText = ""
        speechRecognitionService.resetText()
        practiceState = .playing
        isPlaying = true

        Task { @MainActor in
            do {
                let audioURL = try loadAudioFromAsset()
                try audioSessionManager.configureForRecording()

                // Wait for audio route changes to settle before creating
                // the recording service (configureForRecording triggers
                // route changes that alter the hardware sample rate)
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

                // Re-create recording service after audio session settles
                // so the input node picks up the correct hardware sample rate
                recordingService = AudioRecordingService()
                recordingService.delegate = self

                try recordingService.startRecording()
                try speechRecognitionService.startRecognition()

                try audioPlayerService.play(from: audioURL)
            } catch {
                errorMessage = "Failed to start practice: \(error.localizedDescription)"
                stopAll()
            }
        }
    }

    func replay() {
        stopAll()
        startPractice()
    }

    // MARK: - Private

    private func loadAudioFromAsset() throws -> URL {
        guard let asset = NSDataAsset(name: "onboarding_sample") else {
            throw AudioPlayerError.initializationFailed("onboarding_sample not found in assets")
        }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("onboarding_sample.mp3")
        try asset.data.write(to: tempURL)
        return tempURL
    }

    private func stopAll() {
        cancelListeningTimer()
        audioPlayerService.stop()
        if recordingService.isRecording {
            recordingService.stopRecording()
        }
        speechRecognitionService.stopRecognition()
        isPlaying = false
        practiceState = .idle
    }

    // MARK: - Listening Timer

    private func startListeningTimer() {
        cancelListeningTimer()

        // Give the user 5 seconds after audio finishes to speak
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishPractice()
        }
        listeningTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    private func cancelListeningTimer() {
        listeningTimer?.cancel()
        listeningTimer = nil
    }

    private func finishPractice() {
        // Save recognized text before stopping recognition
        // (canceling recognition may trigger a callback that clears it)
        let savedText = recognizedText

        if recordingService.isRecording {
            recordingService.stopRecording()
        }
        speechRecognitionService.stopRecognition()
        isPlaying = false
        practiceState = .finished
        hasFinishedOnce = true

        // Restore text if it was cleared by the cancellation callback
        if recognizedText.isEmpty && !savedText.isEmpty {
            recognizedText = savedText
        }
    }
}

// MARK: - AudioPlayerServiceDelegate

extension OnboardingPracticeManager: AudioPlayerServiceDelegate {
    func audioDidStart() {}

    func audioDidFinish() {
        practiceState = .listening
        startListeningTimer()
    }

    func audioDidFail(error: Error) {
        errorMessage = "Audio playback failed: \(error.localizedDescription)"
        stopAll()
    }
}

// MARK: - AudioRecordingServiceDelegate

extension OnboardingPracticeManager: AudioRecordingServiceDelegate {
    func didReceiveAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        if speechRecognitionService.isRecognizing {
            speechRecognitionService.processAudioBuffer(buffer)
        }
    }

    func recordingDidFail(error: Error) {
        errorMessage = "Recording failed: \(error.localizedDescription)"
        stopAll()
    }
}

// MARK: - SpeechRecognitionServiceDelegate

extension OnboardingPracticeManager: SpeechRecognitionServiceDelegate {
    func didRecognizeText(_ text: String) {
        // Ignore callbacks after practice is finished
        // (canceling recognition may fire async callbacks with empty text)
        guard practiceState != .finished else { return }
        recognizedText = text
    }

    func recognitionDidFail(error: Error) {
        print("Speech recognition failed: \(error.localizedDescription)")
    }
}
