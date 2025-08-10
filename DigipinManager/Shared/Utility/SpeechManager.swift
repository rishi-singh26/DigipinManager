//
//  SpeechManager.swift
//  DigipinManager
//
//  Created by Rishi Singh on 09/08/25.
//

import Foundation
import AVFoundation

@MainActor
class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var speechContinuation: CheckedContinuation<Void, Never>?
    private var pauseContinuation: CheckedContinuation<Void, Never>?
    private var stopped = false

    // Track whether we're in the middle of a multi-part speech
    private var multiPartSpeechActive = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Audio Session Management
    private func configureAudioSessionForSpeech() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback) // takes over audio
            try session.setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Public Speech Methods
    func speak(_ text: String, language: String = "en-IN") {
        configureAudioSessionForSpeech()
        multiPartSpeechActive = false
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.05
        synthesizer.speak(utterance)
    }

    func speakDigipin(_ text: String, language: String = "en-IN") {
        configureAudioSessionForSpeech()
        multiPartSpeechActive = false
        let modifiedText = text.replacingOccurrences(of: "-", with: "")
            .split(separator: "")
            .joined(separator: " - ")
        print(modifiedText)
        let utterance = AVSpeechUtterance(string: modifiedText)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.01
        synthesizer.speak(utterance)
    }

    /// Speaks a PIN (format: xxx-xxx-xxxx), one digit at a time, with pauses.
    func speakPin(_ pin: String, language: String = "en-IN") async {
        guard pin.count == 12 else {
            print("Error: PIN must be in format xxx-xxx-xxxx")
            return
        }

        configureAudioSessionForSpeech()
        multiPartSpeechActive = true
        stopped = false

        for char in pin {
            if stopped || Task.isCancelled { break }

            // Speak one character and await completion
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.speechContinuation = cont
                let utterance = AVSpeechUtterance(string: String(char))
                utterance.voice = AVSpeechSynthesisVoice(language: language)
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                self.synthesizer.speak(utterance)
            }

            if stopped || Task.isCancelled { break }

            // Pause after character (longer for hyphen)
            let pauseNs: UInt64 = (char == "-") ? 500_000_000 : 200_000_000
            await withCheckedContinuation { cont in
                self.pauseContinuation = cont
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(pauseNs) / 1_000_000_000) {
                    if let p = self.pauseContinuation {
                        self.pauseContinuation = nil
                        p.resume()
                    }
                }
            }
        }

        stopped = false
        multiPartSpeechActive = false
        deactivateAudioSession()
    }

    func stop() {
        stopped = true
        synthesizer.stopSpeaking(at: .immediate)

        // Resume any continuations so the loop can exit
        if let cont = speechContinuation {
            speechContinuation = nil
            cont.resume()
        }
        if let cont = pauseContinuation {
            pauseContinuation = nil
            cont.resume()
        }

        multiPartSpeechActive = false
        deactivateAudioSession()
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.speechContinuation?.resume()
            self.speechContinuation = nil

            // Only deactivate if not in the middle of multi-part speech
            if !self.multiPartSpeechActive {
                self.deactivateAudioSession()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.speechContinuation?.resume()
            self.speechContinuation = nil

            if !self.multiPartSpeechActive {
                self.deactivateAudioSession()
            }
        }
    }
}
