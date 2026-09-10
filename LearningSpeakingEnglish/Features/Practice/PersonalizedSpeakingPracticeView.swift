//
//  PersonalizedSpeakingPracticeView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

/// A lightweight three-step speaking exercise for a personalized POC mission.
struct PersonalizedSpeakingPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SpeakingPracticeViewModel

    init(word: String, sentences: [String], onFinished: @escaping () -> Void) {
        _viewModel = State(initialValue: SpeakingPracticeViewModel(
            word: word,
            sentences: sentences,
            onFinished: onFinished
        ))
    }

    var body: some View {
        Group {
            if viewModel.showSummary {
                summaryView
            } else {
                exerciseView
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(viewModel.showSummary ? "Practice Result" : "Speaking Practice")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showRecordingSheet) {
            RecordingSheetView(
                showRecordingSheet: $viewModel.showRecordingSheet,
                recordingTitle: "Recording step \(viewModel.currentStep + 1)",
                recordingHint: "Speak naturally and clearly",
                recordingSeconds: viewModel.recordingSeconds,
                onStopRecording: viewModel.stopRecording
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
        }
        .alert("Pronunciation check failed", isPresented: Binding(
            get: { viewModel.pronunciationError != nil },
            set: { if !$0 { viewModel.pronunciationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.pronunciationError ?? "Please try recording again.")
        }
        .onDisappear {
            viewModel.cancelAssessment()
        }
    }

    private var exerciseView: some View {
        VStack(spacing: Spacing.lg) {
            LearningStepProgressView(currentStep: viewModel.currentStep + 1, totalSteps: 3)
                .padding(.horizontal)

            VStack(spacing: Spacing.md) {
                Text(viewModel.currentStep == 0 ? "Say this word clearly" : "Practice this sentence")
                    .font(.subheadMedium)
                    .foregroundStyle(.secondary)
                coloredPromptText(prompt: viewModel.currentPrompt, result: viewModel.results[viewModel.currentStep])
                    .font(viewModel.currentStep == 0 ? .largeTitleBold : .title2Bold)
                    .multilineTextAlignment(.center)
                Button {
                    viewModel.playReferenceAudio(for: viewModel.currentPrompt)
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

            if viewModel.hasRecordedCurrentStep || viewModel.isChecking {
                feedbackCard
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                viewModel.startRecording()
            } label: {
                Image.microphone
                    .font(viewModel.microphoneIsSecondary ? .title2Bold : .largeTitleBold)
                    .frame(width: viewModel.microphoneIsSecondary ? 68 : 100, height: viewModel.microphoneIsSecondary ? 68 : 100)
                    .background(viewModel.microphoneIsSecondary ? Color.white : Color.brandPrimary)
                    .clipShape(Circle())
                    .foregroundStyle(viewModel.microphoneIsSecondary ? Color.brandPrimary : Color.white)
                    .overlay {
                        if viewModel.microphoneIsSecondary {
                            Circle().stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                        }
                    }
            }

            if viewModel.hasRecordedCurrentStep {
                HStack(spacing: 12) {
                    Button {
                        viewModel.playUserAttempt(at: viewModel.currentStep)
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
                        viewModel.advance()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(viewModel.microphoneIsSecondary ? Color.brandPrimary : Color.white)
                    .foregroundStyle(viewModel.microphoneIsSecondary ? Color.white : Color.brandPrimary)
                    .overlay {
                        if !viewModel.microphoneIsSecondary {
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
                if viewModel.isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text(viewModel.scoreLabel(for: viewModel.results[viewModel.currentStep]))
                        .font(.subheadSemibold)
                        .foregroundStyle(viewModel.results[viewModel.currentStep].score.color)
                }
            }
            if !viewModel.results[viewModel.currentStep].recognizedText.isEmpty {
                Text("Detected: \(viewModel.results[viewModel.currentStep].recognizedText)")
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

                ForEach(viewModel.prompts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(index == 0 ? "Word" : "Sentence \(index)")
                            .font(.caption1Semibold)
                            .foregroundStyle(.secondary)
                        coloredPromptText(prompt: viewModel.prompts[index], result: viewModel.results[index])
                            .font(.headlineRegular)
                        HStack(spacing: Spacing.sm) {
                            Button {
                                viewModel.playReferenceAudio(for: viewModel.prompts[index])
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
                                viewModel.playUserAttempt(at: index)
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
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                            }
                        }
                        Text(viewModel.scoreLabel(for: viewModel.results[index]))
                            .font(.caption1Semibold)
                            .foregroundStyle(viewModel.results[index].score.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }

                Button("Finish") {
                    viewModel.finishPractice()
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

    private func coloredPromptText(prompt: String, result: PronunciationResult) -> Text {
        let words = prompt.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        return words.enumerated().reduce(Text("")) { output, element in
            let (index, word) = element
            let color = viewModel.wordColor(for: index, promptWord: word, result: result)
            let styledWord = Text(word).foregroundStyle(color)
            if index == 0 {
                return Text("\(styledWord)")
            }
            return Text("\(output) \(styledWord)")
        }
    }
}
