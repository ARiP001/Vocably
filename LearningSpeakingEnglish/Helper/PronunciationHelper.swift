//
//  PronunciationHelper.swift
//  LearningSpeakingEnglish
//

import Foundation
import Speech

/// Runs speech recognition and maps spoken result to app scoring.
enum PronunciationHelper {
    // Keep tasks alive until completion to avoid early deallocation.
    private static var activeTasks: [UUID: SFSpeechRecognitionTask] = [:]

    /// Requests speech-recognition permission from the user.
    static func requestSpeechPermission(_ completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    /// Transcribes recorded audio and returns pronunciation result for target text
    static func analyze(from url: URL, targetText: String, completion: @escaping (PronunciationResult) -> Void) {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            completion(PronunciationResult())
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }

        let taskID = UUID()
        var hasCompleted = false

        let task = recognizer.recognitionTask(with: request) { result, error in
            guard !hasCompleted else { return }

            if let result = result, result.isFinal {
                hasCompleted = true
                let recognizedText = result.bestTranscription.formattedString
                let score = calculateScore(spoken: recognizedText, target: targetText)
                activeTasks[taskID]?.cancel()
                activeTasks.removeValue(forKey: taskID)

                DispatchQueue.main.async {
                    completion(PronunciationResult(recognizedText: recognizedText, score: score))
                }
                return
            }

            if error != nil {
                hasCompleted = true
                activeTasks[taskID]?.cancel()
                activeTasks.removeValue(forKey: taskID)
                DispatchQueue.main.async {
                    completion(PronunciationResult())
                }
            }
        }

        activeTasks[taskID] = task

        // Fallback timeout to avoid hanging state when recognizer stalls.
        DispatchQueue.global().asyncAfter(deadline: .now() + 8) {
            guard !hasCompleted else { return }
            hasCompleted = true
            activeTasks[taskID]?.cancel()
            activeTasks.removeValue(forKey: taskID)

            DispatchQueue.main.async {
                completion(PronunciationResult())
            }
        }
    }

    /// Uses simple normalized text matching to classify pronunciation quality.
    private static func calculateScore(spoken: String, target: String) -> PronunciationScore {
        let cleanSpoken = normalize(spoken)
        let cleanTarget = normalize(target)

        if cleanSpoken.isEmpty || cleanTarget.isEmpty {
            return .unrecognized
        }

        if cleanSpoken == cleanTarget || cleanSpoken.contains(cleanTarget) {
            return .perfect
        }

        if cleanSpoken.hasPrefix(String(cleanTarget.prefix(3))) || cleanTarget.contains(cleanSpoken) {
            return .almost
        }

        return .keepTrying
    }

    /// Normalizes text to make score comparison more forgiving.
    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
    }
}
