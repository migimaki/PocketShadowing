//
//  AudioConstants.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import AVFoundation
import SwiftUI

enum AudioConstants {
    // Speech-based silence detection (using speech-to-text transcription)
    static let speechSilenceTimeout: TimeInterval = 2.0  // seconds without speech transcription
    static let audioBufferSize: AVAudioFrameCount = 1024

    // TTS Configuration
    static let defaultSpeechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    static let defaultLanguage = "en-US"

    // Audio Session
    static let audioSessionCategory: AVAudioSession.Category = .playAndRecord
    static let audioSessionMode: AVAudioSession.Mode = .voiceChat
    // .allowBluetooth: enables Bluetooth headsets
    // .defaultToSpeaker: use speaker for playback (not needed for headphones)
    // Keep it simple - just allowBluetooth for background recording to work
    static let audioSessionOptions: AVAudioSession.CategoryOptions = [.allowBluetooth]

    // UI
    static let minProgressBarHeight: CGFloat = 4.0
    static let controlButtonSize: CGFloat = 60.0
    static let smallControlButtonSize: CGFloat = 44.0
}
