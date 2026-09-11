//
//  SpeakingPracticeViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import Foundation
import Observation

@Observable
final class SpeakingPracticeViewModel {
    let word: String
    let sentences: [String]
    let onFinished: () -> Void

    var currentStep = 0
    var recordingURLs: [URL?] = [nil, nil, nil]
    var results: [PronunciationResult] = [PronunciationResult(), PronunciationResult(), PronunciationResult()]
    var recordingSeconds = 0
    var showRecordingSheet = false
    var showSummary = false
    var isChecking = false
    var pronunciationError: String?

    @ObservationIgnored private var assessmentTask: Task<Void, Never>?

    init(word: String, sentences: [String], onFinished: @escaping () -> Void) {
        self.word = word
        self.sentences = sentences
        self.onFinished = onFinished
    }

    var prompts: [String] {
        let fallbacks = ["Practice the word in a sentence.", "Repeat the word naturally."]
        return [word] + Array((sentences + fallbacks).prefix(2))
    }

    var currentPrompt: String { prompts[currentStep] }
    var hasRecordedCurrentStep: Bool { recordingURLs[currentStep] != nil }

    var microphoneIsSecondary: Bool {
        guard hasRecordedCurrentStep, !isChecking else { return false }
        let result = results[currentStep]
        guard let score = result.percentage, score >= 85 else { return false }
        return result.words.allSatisfy { $0.score >= 80 }
    }

    func advance() {
        if currentStep == 2 {
            showSummary = true
        } else {
            currentStep += 1
        }
    }

    func startRecording() {
        AudioService.startRecording(
            onTick: { [weak self] seconds in
                self?.recordingSeconds = seconds
            },
            completion: { [weak self] started in
                guard let self, started else { return }
                self.recordingSeconds = 0
                self.showRecordingSheet = true
            }
        )
    }

    func stopRecording() {
        let step = currentStep
        showRecordingSheet = false
        guard let url = AudioService.stopRecording() else { return }
        recordingURLs[step] = url
        analyze(url: url, step: step)
    }

    func playReferenceAudio(for prompt: String) {
        SpeechService.speak(prompt)
    }

    func playUserAttempt(at step: Int) {
        if let url = recordingURLs[step] {
            AudioService.play(url: url)
        }
    }

    func finishPractice() {
        cleanupRecordings()
        onFinished()
    }

    func cancelAssessment() {
        assessmentTask?.cancel()
        isChecking = false
    }

    func scoreLabel(for result: PronunciationResult) -> String {
        guard let percentage = result.percentage else {
            return result.score.title
        }
        return "\(result.score.title) · PronScore: \(Int(percentage.rounded()))/100"
    }

    func evaluatedWords(prompt: String, result: PronunciationResult) -> [EvaluatedWord] {
        let words = prompt.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        return words.enumerated().map { index, promptWord in
            let accuracy: WordAccuracy
            if result.words.indices.contains(index) {
                accuracy = WordAccuracy(score: result.words[index].score)
            } else if let percentage = result.percentage {
                let normalizedPromptWord = promptWord.lowercased().filter(\.isLetter)
                let recognized = result.recognizedText
                    .split(whereSeparator: { !$0.isLetter })
                    .map { $0.lowercased() }
                if recognized.contains(normalizedPromptWord) {
                    accuracy = WordAccuracy(score: percentage)
                } else {
                    accuracy = .poor
                }
            } else {
                accuracy = .unassessed
            }
            return EvaluatedWord(word: promptWord, accuracy: accuracy)
        }
    }

    private func analyze(url: URL, step: Int) {
        isChecking = true
        assessmentTask?.cancel()
        assessmentTask = Task { @MainActor in
            do {
                guard let service = PronunciationService.configured else {
                    throw PronunciationServiceError.missingConfiguration
                }
                let result = try await service.assess(fileURL: url, referenceText: prompts[step])
                results[step] = result
            } catch {
                if Task.isCancelled { return }
                results[step] = PronunciationResult()
                pronunciationError = error.localizedDescription
                print("Azure pronunciation assessment failed: \(error)")
            }
            isChecking = false
            assessmentTask = nil
        }
    }

    private func cleanupRecordings() {
        recordingURLs.compactMap { $0 }.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
}
