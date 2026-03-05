//
//  TextToSpeechService.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import AVFoundation
import Foundation

protocol TextToSpeechServiceDelegate: AnyObject {
    func speechDidStart()
    func speechDidFinish()
    func speechDidCancel()
}

class TextToSpeechService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    weak var delegate: TextToSpeechServiceDelegate?

    private var currentUtterance: AVSpeechUtterance?
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: String = AudioConstants.defaultLanguage, rate: Float = AudioConstants.defaultSpeechRate) {
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate

        currentUtterance = utterance
        isSpeaking = true

        synthesizer.speak(utterance)
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
    }

    func stop() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        delegate?.speechDidStart()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = nil
        delegate?.speechDidFinish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        currentUtterance = nil
        delegate?.speechDidCancel()
    }
}
