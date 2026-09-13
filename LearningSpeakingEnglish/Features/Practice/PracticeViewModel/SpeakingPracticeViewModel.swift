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
        guard hasRecordedCurrentStep,
              !isChecking,
              let score = results[currentStep].percentage,
              score >= 85 else {
            return false
        }
        return results[currentStep].words.allSatisfy { $0.score >= 80 }
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
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.recordingSeconds = 0
                    self.showRecordingSheet = true
                case .failure(let error):
                    self.pronunciationError = error.localizedDescription
                }
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
            evaluateWord(promptWord, at: index, against: result)
        }
    }

    private func evaluateWord(
        _ promptWord: String,
        at index: Int,
        against result: PronunciationResult
    ) -> EvaluatedWord {
        if result.words.indices.contains(index) {
            return EvaluatedWord(word: promptWord, accuracy: WordAccuracy(score: result.words[index].score))
        }
        guard let percentage = result.percentage else {
            return EvaluatedWord(word: promptWord, accuracy: .unassessed)
        }
        let accuracy = matchAccuracyFromRecognizedText(word: promptWord, result: result, percentage: percentage)
        return EvaluatedWord(word: promptWord, accuracy: accuracy)
    }

    private func matchAccuracyFromRecognizedText(
        word promptWord: String,
        result: PronunciationResult,
        percentage: Double
    ) -> WordAccuracy {
        let normalizedPromptWord = promptWord.lowercased().filter(\.isLetter)
        let recognizedWords = result.recognizedText
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.lowercased() }

        return recognizedWords.contains(normalizedPromptWord)
            ? WordAccuracy(score: percentage)
            : .poor
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
            } catch PronunciationServiceError.missingConfiguration {
                handleAssessmentError("Azure Speech credentials are not configured. Please check Info.plist.", step: step)
            } catch PronunciationServiceError.emptyResult {
                handleAssessmentError("No speech detected. Please speak clearly into the microphone.", step: step)
            } catch PronunciationServiceError.httpError(let statusCode) {
                handleAssessmentError("Pronunciation service error (HTTP \(statusCode)). Please try again later.", step: step)
            } catch let urlError as URLError where urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                handleAssessmentError("Check your internet connection to assess pronunciation.", step: step)
            } catch {
                handleAssessmentError("Unable to evaluate pronunciation: \(error.localizedDescription)", step: step)
            }
            isChecking = false
            assessmentTask = nil
        }
    }

    private func handleAssessmentError(_ message: String, step: Int) {
        guard !Task.isCancelled else { return }
        results[step] = PronunciationResult()
        pronunciationError = message
    }

    private func cleanupRecordings() {
        recordingURLs.compactMap { $0 }.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
}
