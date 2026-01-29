//
//  SpeechRecognitionService.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import Foundation
import Speech
import AVFoundation

protocol SpeechRecognitionServiceDelegate: AnyObject {
    func didRecognizeText(_ text: String)
    func recognitionDidFail(error: Error)
}

enum SpeechRecognitionError: Error {
    case notAuthorized
    case recognizerUnavailable
}

class SpeechRecognitionService {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    weak var delegate: SpeechRecognitionServiceDelegate?

    private(set) var isRecognizing = false
    private(set) var recognizedText = ""
    private(set) var lastTranscriptionTime: Date?

    /// Language code to locale mapping
    private static func locale(for languageCode: String) -> Locale {
        switch languageCode {
        case "en":
            return Locale(identifier: "en-US")
        case "ja":
            return Locale(identifier: "ja-JP")
        case "fr":
            return Locale(identifier: "fr-FR")
        default:
            return Locale(identifier: "en-US")
        }
    }

    /// Initialize with language code (en, ja, fr)
    init(languageCode: String = "en") {
        let locale = Self.locale(for: languageCode)
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    /// Initialize with locale (for backwards compatibility)
    init(locale: Locale) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    func startRecognition() throws {
        // Cancel any ongoing recognition
        stopRecognition()

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false // Use server for better accuracy

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.recognitionDidFail(error: error)
                }
                self.stopRecognition()
                return
            }

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.recognizedText = transcription

                // Update timestamp for any transcription (partial or final)
                if !transcription.isEmpty {
                    self.lastTranscriptionTime = Date()
                }

                DispatchQueue.main.async {
                    self.delegate?.didRecognizeText(transcription)
                }

                // If result is final, stop recognition
                if result.isFinal {
                    self.stopRecognition()
                }
            }
        }

        isRecognizing = true
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecognizing = false
        lastTranscriptionTime = nil
    }

    func resetText() {
        recognizedText = ""
        lastTranscriptionTime = nil
    }
}
