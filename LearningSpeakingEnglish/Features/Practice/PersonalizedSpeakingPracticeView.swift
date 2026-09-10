//
//  PersonalizedSpeakingPracticeView.swift
//  LearningSpeakingEnglish
//

import AVFoundation
import SwiftUI

/// A lightweight three-step speaking exercise for a personalized POC mission.
struct PersonalizedSpeakingPracticeView: View {
    let word: String
    let sentences: [String]
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var recordingURLs: [URL?] = [nil, nil, nil]
    @State private var results: [PronunciationResult] = [PronunciationResult(), PronunciationResult(), PronunciationResult()]
    @State private var recorder: AVAudioRecorder?
    @State private var recordingSeconds = 0
    @State private var recordingTimer: Timer?
    @State private var showRecordingSheet = false
    @State private var isChecking = false
    @State private var showSummary = false
    @State private var pronunciationError: String?
    @State private var assessmentTask: Task<Void, Never>?

    private var prompts: [String] {
        let fallbacks = ["Practice the word in a sentence.", "Repeat the word naturally."]
        return [word] + Array((sentences + fallbacks).prefix(2))
    }

    private var currentPrompt: String { prompts[currentStep] }
    private var hasRecordedCurrentStep: Bool { recordingURLs[currentStep] != nil }

    private var microphoneIsSecondary: Bool {
        guard hasRecordedCurrentStep, !isChecking else { return false }
        let result = results[currentStep]
        guard let score = result.percentage, score >= 85 else { return false }
        return result.words.allSatisfy { $0.score >= 80 }
    }

    var body: some View {
        Group {
            if showSummary {
                summaryView
            } else {
                exerciseView
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(showSummary ? "Practice Result" : "Speaking Practice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRecordingSheet) {
            RecordingSheetView(
                showRecordingSheet: $showRecordingSheet,
                recordingTitle: "Recording step \(currentStep + 1)",
                recordingHint: "Speak naturally and clearly",
                recordingSeconds: recordingSeconds,
                onStopRecording: stopRecording
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
        }
        .alert("Pronunciation check failed", isPresented: Binding(
            get: { pronunciationError != nil },
            set: { if !$0 { pronunciationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pronunciationError ?? "Please try recording again.")
        }
        .onDisappear {
            assessmentTask?.cancel()
            isChecking = false
        }
    }

    private var exerciseView: some View {
        VStack(spacing: Spacing.lg) {
            LearningStepProgressView(currentStep: currentStep + 1, totalSteps: 3)
                .padding(.horizontal)

            VStack(spacing: Spacing.md) {
                Text(currentStep == 0 ? "Say this word clearly" : "Practice this sentence")
                    .font(.subheadMedium)
                    .foregroundStyle(.secondary)
                coloredPromptText(prompt: currentPrompt, result: results[currentStep])
                    .font(currentStep == 0 ? .system(size: 40, weight: .bold) : .title2Bold)
                    .multilineTextAlignment(.center)
                Button {
                    SpeechHelper.speak(currentPrompt)
                } label: {
                    Label {
                        Text("Listen")
                    } icon: {
                        Image.speaker
                    }
                    .font(.subheadMedium)
                    .foregroundStyle(Color.brandSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brandSecondary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .padding(.horizontal)

            if hasRecordedCurrentStep || isChecking {
                feedbackCard
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                startRecording()
            } label: {
                Image.microphone
                    .font(.system(size: microphoneIsSecondary ? 25 : 38, weight: .medium))
                    .frame(width: microphoneIsSecondary ? 68 : 100, height: microphoneIsSecondary ? 68 : 100)
                    .background(microphoneIsSecondary ? Color.white : Color.brandPrimary)
                    .clipShape(Circle())
                    .foregroundStyle(microphoneIsSecondary ? Color.brandPrimary : Color.white)
                    .overlay {
                        if microphoneIsSecondary {
                            Circle().stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                        }
                    }
            }

            if hasRecordedCurrentStep {
                HStack(spacing: 12) {
                    Button {
                        if let url = recordingURLs[currentStep] {
                            RecordingPlaybackHelper.play(url: url)
                        }
                    } label: {
                        Label {
                            Text("Your attempt")
                        } icon: {
                            Image.waveform
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white)
                        .foregroundStyle(Color.brandPrimary)
                            .clipShape(Capsule())
                    }

                    Button("Next") {
                        advance()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(microphoneIsSecondary ? Color.brandPrimary : Color.white)
                    .foregroundStyle(microphoneIsSecondary ? Color.white : Color.brandPrimary)
                    .overlay {
                        if !microphoneIsSecondary {
                            Capsule().stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1)
                        }
                    }
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Pronunciation check")
                    .font(.subheadSemibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text(scoreLabel(for: results[currentStep]))
                        .font(.subheadSemibold)
                        .foregroundStyle(results[currentStep].score.color)
                }
            }
            if !results[currentStep].recognizedText.isEmpty {
                Text("Detected: \(results[currentStep].recognizedText)")
                    .font(.subheadRegular)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("Listen and compare before you finish")
                    .font(.subheadRegular)
                    .foregroundStyle(.secondary)

                ForEach(prompts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(index == 0 ? "Word" : "Sentence \(index)")
                            .font(.caption1Semibold)
                            .foregroundStyle(.secondary)
                        coloredPromptText(prompt: prompts[index], result: results[index])
                            .font(.headlineRegular)
                        HStack(spacing: Spacing.sm) {
                            Button {
                                 SpeechHelper.speak(prompts[index])
                            } label: {
                                Label {
                                    Text("Reference")
                                } icon: {
                                    Image.play
                                }
                                .font(.subheadMedium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.white)
                                .foregroundStyle(Color.brandPrimary)
                                .clipShape(Capsule())
                            }

                            Button {
                                if let url = recordingURLs[index] { RecordingPlaybackHelper.play(url: url) }
                            } label: {
                                Label {
                                    Text("Your attempt")
                                } icon: {
                                    Image.waveform
                                }
                                .font(.subheadMedium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.brandPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            }
                        }
                        Text(scoreLabel(for: results[index]))
                            .font(.caption1Semibold)
                            .foregroundStyle(results[index].score.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }

                Button("Finish") {
                    cleanupRecordings()
                    onFinished()
                    dismiss()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding()
        }
    }

    private func advance() {
        if currentStep == 2 {
            showSummary = true
        } else {
            currentStep += 1
        }
    }

    private func startRecording() {
        RecordingHelper.requestMicrophonePermission { granted in
            guard granted else { return }
            do {
                let newRecorder = try RecordingHelper.makeRecorder(fileName: "poc-\(UUID().uuidString).wav")
                recorder = newRecorder
                recordingSeconds = 0
                newRecorder.record()
                recordingTimer?.invalidate()
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    recordingSeconds += 1
                }
                showRecordingSheet = true
            } catch {
                recorder = nil
            }
        }
    }

    private func stopRecording() {
        let step = currentStep
        recorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        guard let url = recorder?.url else {
            showRecordingSheet = false
            return
        }
        recordingURLs[step] = url
        recorder = nil
        showRecordingSheet = false
        analyze(url: url, step: step)
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

    private func scoreLabel(for result: PronunciationResult) -> String {
        guard let percentage = result.percentage else {
            return result.score.title
        }
        return "\(result.score.title) · PronScore: \(Int(percentage.rounded()))/100"
    }

    private func coloredPromptText(prompt: String, result: PronunciationResult) -> Text {
        let words = prompt.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        return words.enumerated().reduce(Text("")) { output, element in
            let (index, word) = element
            let color = wordColor(for: index, promptWord: word, result: result)
            let styledWord = Text(word).foregroundColor(color)
            if index == 0 {
                return Text("\(styledWord)")
            }
            return Text("\(output) \(styledWord)")
        }
    }

    private func wordColor(for index: Int, promptWord: String, result: PronunciationResult) -> Color {
        if result.words.indices.contains(index) {
            return result.words[index].color
        }
        guard let percentage = result.percentage else { return .primary }
        let normalizedPromptWord = promptWord.lowercased().filter(\.isLetter)
        let recognized = result.recognizedText
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.lowercased() }
        guard recognized.contains(normalizedPromptWord) else { return .red }
        return PronunciationWordResult(word: promptWord, score: percentage).color
    }

    private func cleanupRecordings() {
        recordingURLs.compactMap { $0 }.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
}
