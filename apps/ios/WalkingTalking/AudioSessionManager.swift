//
//  AudioSessionManager.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import AVFoundation
import Foundation

protocol AudioSessionManagerDelegate: AnyObject {
    func audioSessionInterrupted()
    func audioSessionResumed()
    func audioRouteChanged()
}

class AudioSessionManager {
    static let shared = AudioSessionManager()

    weak var delegate: AudioSessionManagerDelegate?

    private init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    func configureForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio)
        try session.setActive(true)
    }

    func configureForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            AudioConstants.audioSessionCategory,
            mode: AudioConstants.audioSessionMode,
            options: AudioConstants.audioSessionOptions
        )
        try session.setActive(true)
    }

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Audio Device Info

    func getCurrentInputDevice() -> String {
        let session = AVAudioSession.sharedInstance()
        if let input = session.currentRoute.inputs.first {
            return input.portName
        }
        return "No input device"
    }

    func getCurrentOutputDevice() -> String {
        let session = AVAudioSession.sharedInstance()
        if let output = session.currentRoute.outputs.first {
            return output.portName
        }
        return "No output device"
    }

    func getAvailableInputDevices() -> [String] {
        let session = AVAudioSession.sharedInstance()
        guard let availableInputs = session.availableInputs else {
            return []
        }
        return availableInputs.map { $0.portName }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Pause playback/recording
            delegate?.audioSessionInterrupted()

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Resume if appropriate
                delegate?.audioSessionResumed()
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        print("[AudioSessionManager] Route change reason: \(reason.rawValue)")

        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged, pause playback
            print("[AudioSessionManager] Old device unavailable - pausing")
            delegate?.audioSessionInterrupted()

        case .newDeviceAvailable:
            // New audio device connected
            print("[AudioSessionManager] New device available - notifying delegate")
            delegate?.audioRouteChanged()

        case .categoryChange:
            // Audio category changed
            print("[AudioSessionManager] Category changed - notifying delegate")
            delegate?.audioRouteChanged()

        case .override:
            // System override (e.g., route to speaker)
            print("[AudioSessionManager] Route override - notifying delegate")
            delegate?.audioRouteChanged()

        case .wakeFromSleep:
            // Device woke from sleep
            print("[AudioSessionManager] Wake from sleep - notifying delegate")
            delegate?.audioRouteChanged()

        case .noSuitableRouteForCategory:
            // No suitable route for category
            print("[AudioSessionManager] No suitable route - interrupting")
            delegate?.audioSessionInterrupted()

        case .routeConfigurationChange:
            // Route configuration changed (common during background transitions)
            print("[AudioSessionManager] Route configuration changed - notifying delegate")
            delegate?.audioRouteChanged()

        default:
            print("[AudioSessionManager] Unhandled route change reason: \(reason.rawValue)")
            break
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
