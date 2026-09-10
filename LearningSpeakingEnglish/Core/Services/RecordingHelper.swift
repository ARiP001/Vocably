//
//  RecordingHelper.swift
//  LearningSpeakingEnglish
//

import AVFoundation

/// Handles microphone permission and recorder creation.
enum RecordingHelper {
    /// Requests microphone access and returns the result on main thread.
    static func requestMicrophonePermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Creates a 16 kHz mono PCM WAV recorder for pronunciation assessment.
    static func makeRecorder(fileName: String) throws -> AVAudioRecorder {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = folder.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true)

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.prepareToRecord()
        return recorder
    }

}

/// Plays previously saved user recordings.
enum RecordingPlaybackHelper {
    private static var player: AVAudioPlayer?

    /// Plays audio from a local file URL.
    static func play(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Keep app responsive if playback fails.
        }
    }
}
