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

    private var prompts: [String] {
        let fallbacks = ["Practice the word in a sentence.", "Repeat the word naturally."]
        return [word] + Array((sentences + fallbacks).prefix(2))
    }

    private var currentPrompt: String { prompts[currentStep] }
    private var hasRecordedCurrentStep: Bool { recordingURLs[currentStep] != nil }

    var body: some View {
        Group {
            if showSummary {
                summaryView
            } else {
                exerciseView
            }
        }
        .background(Color(.systemGroupedBackground))
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
    }

    private var exerciseView: some View {
        VStack(spacing: 20) {
            LearningStepProgressView(currentStep: currentStep + 1, totalSteps: 3)
                .padding(.horizontal)

            VStack(spacing: 14) {
                Text(currentStep == 0 ? "Say this word clearly" : "Practice this sentence")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(currentPrompt)
                    .font(currentStep == 0 ? .system(size: 40, weight: .bold) : .title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Button {
                    SpeechHelper.speak(currentPrompt)
                } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appSecondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)

            if hasRecordedCurrentStep || isChecking {
                feedbackCard
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                startRecording()
            } label: {
                Image(systemName: "microphone")
                    .font(.largeTitle)
                    .frame(width: 100, height: 100)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
                    .foregroundStyle(.white)
            }

            if hasRecordedCurrentStep {
                HStack(spacing: 12) {
                    Button {
                        if let url = recordingURLs[currentStep] {
                            RecordingPlaybackHelper.play(url: url)
                        }
                    } label: {
                        Label("Your attempt", systemImage: "waveform")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(Color.appPrimary)
                            .clipShape(Capsule())
                    }

                    Button(currentStep == 2 ? "Compare" : "Next") {
                        advance()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pronunciation check")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text(results[currentStep].score.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(results[currentStep].score.color)
                }
            }
            if !results[currentStep].recognizedText.isEmpty {
                Text("Detected: \(results[currentStep].recognizedText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Listen and compare before you finish")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(prompts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(index == 0 ? "Word" : "Sentence \(index)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(prompts[index])
                            .font(.headline)
                        HStack {
                            Button("Reference") { SpeechHelper.speak(prompts[index]) }
                            Spacer()
                            Button("Your attempt") {
                                if let url = recordingURLs[index] { RecordingPlaybackHelper.play(url: url) }
                            }
                        }
                        .foregroundStyle(Color.appPrimary)
                        Text(results[index].score.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(results[index].score.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Button("Finish") {
                    onFinished()
                    dismiss()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appPrimary)
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
                let newRecorder = try RecordingHelper.makeRecorder(fileName: "poc-\(UUID().uuidString).m4a")
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
        PronunciationHelper.requestSpeechPermission { granted in
            guard granted else {
                isChecking = false
                return
            }
            PronunciationHelper.analyze(from: url, targetText: prompts[step]) { result in
                results[step] = result
                isChecking = false
            }
        }
    }
}
