//
//  AudioPlayerService.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import AVFoundation

protocol AudioPlayerServiceDelegate: AnyObject {
    func audioDidStart()
    func audioDidFinish()
    func audioDidFail(error: Error)
}

/// Service for playing audio files from Supabase Storage
class AudioPlayerService: NSObject {
    weak var delegate: AudioPlayerServiceDelegate?

    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying: Bool = false
    private var stopTimer: Timer? // Timer to stop playback at specified duration

    /// Play audio from a local file URL with optional timestamp seeking
    /// - Parameters:
    ///   - localURL: Local file URL of the audio
    ///   - startTime: Optional start time in seconds (for timestamp-based playback)
    ///   - duration: Optional duration in seconds (will stop after this duration)
    func play(from localURL: URL, startTime: TimeInterval? = nil, duration: TimeInterval? = nil) throws {
        // Stop any current playback and timers
        stop()

        // Create audio player
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: localURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Seek to start time if provided (timestamp-based playback)
            if let startTime = startTime {
                audioPlayer?.currentTime = startTime
                print("🔊 Seeking to \(String(format: "%.2f", startTime))s")
            }

            // Start playback
            guard audioPlayer?.play() == true else {
                throw AudioPlayerError.playbackFailed
            }

            isPlaying = true
            delegate?.audioDidStart()

            if let startTime = startTime, let duration = duration {
                print("🔊 Playing audio segment: \(String(format: "%.2f", startTime))s - \(String(format: "%.2f", startTime + duration))s (\(String(format: "%.2f", duration))s duration)")
            } else {
                print("🔊 Playing audio: \(localURL.lastPathComponent)")
            }

            // Schedule stop timer if duration is specified
            if let duration = duration {
                scheduleStopTimer(after: duration)
            }

        } catch {
            throw AudioPlayerError.initializationFailed(error.localizedDescription)
        }
    }

    /// Schedule a timer to stop playback after specified duration
    private func scheduleStopTimer(after duration: TimeInterval) {
        stopTimer?.invalidate()
        stopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("⏱️ Timer triggered - stopping playback after \(String(format: "%.2f", duration))s")
            self.stopPlaybackAndNotify()
        }
    }

    /// Stop playback and notify delegate
    private func stopPlaybackAndNotify() {
        guard isPlaying else { return }

        audioPlayer?.stop()
        isPlaying = false
        stopTimer?.invalidate()
        stopTimer = nil

        print("✅ Timestamp-based playback finished")
        delegate?.audioDidFinish()
    }

    /// Stop current playback
    func stop() {
        stopTimer?.invalidate()
        stopTimer = nil

        if let player = audioPlayer, player.isPlaying {
            player.stop()
            isPlaying = false
        }
        audioPlayer = nil
    }

    /// Pause current playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    /// Resume playback
    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    /// Get current playback time
    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    /// Get total duration
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false

        if flag {
            print("✅ Audio finished playing")
            delegate?.audioDidFinish()
        } else {
            print("❌ Audio playback interrupted")
            delegate?.audioDidFail(error: AudioPlayerError.playbackInterrupted)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        let error = error ?? AudioPlayerError.decodingError
        print("❌ Audio decode error: \(error.localizedDescription)")
        delegate?.audioDidFail(error: error)
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        print("[AudioPlayerService] ⚠️ Audio playback interrupted (begin)")
        isPlaying = false
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        print("[AudioPlayerService] 🔄 Audio interruption ended, flags: \(flags)")
        // Flags: 1 = should resume
        if flags == 1 {
            print("[AudioPlayerService] Resuming playback after interruption")
            player.play()
            isPlaying = true
        }
    }
}

// MARK: - Errors

enum AudioPlayerError: Error, LocalizedError {
    case initializationFailed(String)
    case playbackFailed
    case playbackInterrupted
    case decodingError

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Failed to initialize audio player: \(reason)"
        case .playbackFailed:
            return "Failed to start playback"
        case .playbackInterrupted:
            return "Playback was interrupted"
        case .decodingError:
            return "Failed to decode audio file"
        }
    }
}
