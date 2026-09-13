//
//  SpeechService.swift
//  LearningSpeakingEnglish
//

import AVFoundation

/// Menangani pemutaran suara text-to-speech (TTS) untuk kosakata dan kalimat latihan.
enum SpeechService {
    private static let synthesizer = AVSpeechSynthesizer()

    /// Melafalkan teks menggunakan suara bahasa yang diminta.
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
            // Menjaga alur aplikasi tetap lancar jika inisialisasi audio session gagal.
        }
        // Hentikan pelafalan yang sedang aktif agar respons ketukan tombol terbaru terdengar seketika.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0

        synthesizer.speak(utterance)
    }

    /// Menghentikan pelafalan seketika jika sintesis ucapan sedang aktif.
    static func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
