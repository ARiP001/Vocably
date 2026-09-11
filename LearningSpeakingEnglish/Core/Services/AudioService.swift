//
//  AudioService.swift
//  LearningSpeakingEnglish
//

import AVFoundation

/// Consolidated service for microphone recording and audio playback.
enum AudioService {
    private static var player: AVAudioPlayer?
    private static var currentRecorder: AVAudioRecorder?
    private static var recordingTimer: Timer?
    private static var elapsedSeconds: Int = 0

    // MARK: - Microphone & Recording

    /// Requests microphone access and returns the result on main thread.
    static func requestMicrophonePermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Starts a recording session with an automated duration tick timer.
    static func startRecording(
        onTick: @escaping (Int) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        requestMicrophonePermission { granted in
            guard granted else {
                completion(false)
                return
            }

            do {
                let fileName = "poc-\(UUID().uuidString).wav"
                let recorder = try makeRecorder(fileName: fileName)
                currentRecorder = recorder
                recorder.record()
                startTickTimer(onTick: onTick)
                completion(true)
            } catch {
                currentRecorder = nil
                stopTickTimer()
                completion(false)
            }
        }
    }

    /// Stops the active recording session and returns the recorded audio file URL.
    static func stopRecording() -> URL? {
        stopTickTimer()
        guard let recorder = currentRecorder else { return nil }
        recorder.stop()
        let url = recorder.url
        currentRecorder = nil
        return url
    }

    // MARK: - Recording Helpers

    /// Creates a 16 kHz mono PCM WAV recorder for pronunciation assessment.
    private static func makeRecorder(fileName: String) throws -> AVAudioRecorder {
        let fileURL = try recordingFileURL(fileName: fileName)
        let settings = pcm16kHzSettings()
        try configureRecordSession()

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.prepareToRecord()
        return recorder
    }

    private static func recordingFileURL(fileName: String) throws -> URL {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "AudioServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document directory not found"])
        }
        return folder.appendingPathComponent(fileName)
    }

    private static func pcm16kHzSettings() -> [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
    }

    private static func configureRecordSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true)
    }

    private static func startTickTimer(onTick: @escaping (Int) -> Void) {
        stopTickTimer()
        elapsedSeconds = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
            onTick(elapsedSeconds)
        }
    }

    private static func stopTickTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Playback

    /// Plays audio from a local file URL.
    static func play(url: URL) {
        do {
            try configurePlaybackSession()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Keep app responsive if playback fails.
        }
    }

    private static func configurePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }

    /// Stops currently playing audio if active.
    static func stopPlayback() {
        player?.stop()
        player = nil
    }
}
