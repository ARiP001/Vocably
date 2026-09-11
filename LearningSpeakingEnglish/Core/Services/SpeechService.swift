//
//  SpeechService.swift
//  LearningSpeakingEnglish
//

import AVFoundation

/// Handles text-to-speech playback for vocab and sentence prompts.
enum SpeechService {
    private static let synthesizer = AVSpeechSynthesizer()

    /// Speaks input text using the requested language voice.
    static func speak(_ text: String, languageCode: String = "en-US") {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.isEmpty {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Keep the app flow smooth even when audio session setup fails.
        }
        // Stop current utterance so the newest tap response is immediate.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0

        synthesizer.speak(utterance)
    }

    /// Stops speaking immediately if speech synthesis is currently active.
    static func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
