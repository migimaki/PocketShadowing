//
//  AudioRecordingService.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import AVFoundation
import Foundation

protocol AudioRecordingServiceDelegate: AnyObject {
    func didReceiveAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime)
    func recordingDidFail(error: Error)
}

enum AudioRecordingError: Error {
    case permissionDenied
    case audioEngineNotRunning
    case inputNodeUnavailable
}

class AudioRecordingService {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    weak var delegate: AudioRecordingServiceDelegate?

    private(set) var isRecording = false

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startRecording() throws {
        guard !isRecording else { return }

        // Get input node
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw AudioRecordingError.inputNodeUnavailable
        }

        // Get the current hardware format from the input node
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create a format converter if needed to handle different sample rates
        // Use a standard format that works across all devices
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: 1,
            interleaved: false
        )

        guard let format = recordingFormat else {
            throw AudioRecordingError.inputNodeUnavailable
        }

        // Install tap on input node to receive audio buffers
        var bufferCount = 0
        inputNode.installTap(
            onBus: 0,
            bufferSize: AudioConstants.audioBufferSize,
            format: format
        ) { [weak self] buffer, time in
            bufferCount += 1
            if bufferCount % 100 == 0 {
                print("[AudioRecordingService] Received \(bufferCount) audio buffers")
            }
            self?.delegate?.didReceiveAudioBuffer(buffer, time: time)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            inputNode.removeTap(onBus: 0)
            throw error
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        // Remove tap and stop engine
        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()

        isRecording = false
    }

    func ensureEngineRunning() {
        // Check if engine is running, restart if needed (for background transitions)
        if isRecording && !audioEngine.isRunning {
            print("[AudioRecordingService] Audio engine stopped unexpectedly, restarting...")
            do {
                try audioEngine.start()
                print("[AudioRecordingService] Audio engine restarted successfully")
            } catch {
                print("[AudioRecordingService] Failed to restart audio engine: \(error)")
                delegate?.recordingDidFail(error: error)
            }
        }
    }

    func cleanup() {
        if isRecording {
            stopRecording()
        }
    }

    deinit {
        cleanup()
    }
}
