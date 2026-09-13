//
//  AudioService.swift
//  LearningSpeakingEnglish
//

import AVFoundation

enum AudioServiceError: LocalizedError {
    case permissionDenied
    case directoryNotFound
    case sessionSetupFailed(Error)
    case recorderInitializationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied. Please enable microphone access in iOS Settings to practice speaking."
        case .directoryNotFound:
            return "Unable to locate document directory for audio recording."
        case .sessionSetupFailed(let error):
            return "Failed to configure audio session: \(error.localizedDescription)"
        case .recorderInitializationFailed(let error):
            return "Failed to initialize audio recorder: \(error.localizedDescription)"
        }
    }
}

/// Layanan terpadu untuk perekaman mikrofon dan pemutaran audio pengguna.
enum AudioService {
    private static var player: AVAudioPlayer?
    private static var currentRecorder: AVAudioRecorder?
    private static var recordingTimer: Timer?
    private static var elapsedSeconds: Int = 0

    // MARK: - Microphone & Recording

    /// Meminta izin akses mikrofon dan mengembalikan hasilnya di main thread.
    static func requestMicrophonePermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Memulai sesi perekaman dengan timer durasi otomatis.
    static func startRecording(
        onTick: @escaping (Int) -> Void,
        completion: @escaping (Result<Void, AudioServiceError>) -> Void
    ) {
        requestMicrophonePermission { granted in
            guard granted else {
                completion(.failure(.permissionDenied))
                return
            }

            do {
                let fileName = "poc-\(UUID().uuidString).wav"
                let recorder = try makeRecorder(fileName: fileName)
                currentRecorder = recorder
                recorder.record()
                startTickTimer(onTick: onTick)
                completion(.success(()))
            } catch let error as AudioServiceError {
                currentRecorder = nil
                stopTickTimer()
                completion(.failure(error))
            } catch {
                currentRecorder = nil
                stopTickTimer()
                completion(.failure(.recorderInitializationFailed(error)))
            }
        }
    }

    /// Menghentikan sesi perekaman aktif dan mengembalikan URL file audio yang terekam.
    static func stopRecording() -> URL? {
        stopTickTimer()
        guard let recorder = currentRecorder else { return nil }
        recorder.stop()
        let url = recorder.url
        currentRecorder = nil
        return url
    }

    // MARK: - Helper Perekaman

    /// Membuat recorder WAV Linear PCM 16 kHz mono untuk penilaian pengucapan Azure.
    private static func makeRecorder(fileName: String) throws -> AVAudioRecorder {
        let fileURL = try recordingFileURL(fileName: fileName)
        let settings = pcm16kHzSettings()
        try configureRecordSession()

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.prepareToRecord()
            return recorder
        } catch {
            throw AudioServiceError.recorderInitializationFailed(error)
        }
    }

    private static func recordingFileURL(fileName: String) throws -> URL {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioServiceError.directoryNotFound
        }
        return folder.appendingPathComponent(fileName)
    }

    private static func pcm16kHzSettings() -> [String: Any] {
        // REST API Azure Speech Pronunciation Assessment secara ketat mewajibkan sample rate 16 kHz,
        // Linear PCM 16-bit, dan channel mono. Audio terkompresi (seperti AAC) akan ditolak dengan error HTTP 400.
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
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .duckOthers])
            try session.setActive(true)
        } catch {
            throw AudioServiceError.sessionSetupFailed(error)
        }
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

    // MARK: - Pemutaran Audio

    /// Memutar audio dari URL file lokal.
    static func play(url: URL) {
        do {
            try configurePlaybackSession()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Menjaga aplikasi tetap responsif jika terjadi kegagalan pemutaran audio.
        }
    }

    private static func configurePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }

    /// Menghentikan pemutaran audio jika sedang aktif.
    static func stopPlayback() {
        player?.stop()
        player = nil
    }
}
