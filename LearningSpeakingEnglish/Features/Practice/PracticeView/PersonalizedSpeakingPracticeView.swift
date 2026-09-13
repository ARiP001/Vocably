//
//  PersonalizedSpeakingPracticeView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

/// Tampilan latihan berbicara 3-langkah untuk misi yang dipersonalisasi.
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
        exerciseView
            .background(Color.bgPrimary)
            .navigationTitle("Speaking Practice")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.showSummary) {
                SpeakingPracticeSummaryView(viewModel: viewModel) {
                    dismiss()
                }
            }
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
                EvaluatedPromptText(evaluatedWords: viewModel.evaluatedWords(prompt: viewModel.currentPrompt, result: viewModel.results[viewModel.currentStep]))
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
                    .font(viewModel.isCurrentStepPassed ? .title2Bold : .largeTitleBold)
                    .frame(width: viewModel.isCurrentStepPassed ? 68 : 100, height: viewModel.isCurrentStepPassed ? 68 : 100)
                    .background(viewModel.isCurrentStepPassed ? Color.white : Color.brandPrimary)
                    .clipShape(Circle())
                    .foregroundStyle(viewModel.isCurrentStepPassed ? Color.brandPrimary : Color.white)
                    .overlay {
                        if viewModel.isCurrentStepPassed {
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
                    .background(viewModel.isCurrentStepPassed ? Color.brandPrimary : Color.white)
                    .foregroundStyle(viewModel.isCurrentStepPassed ? Color.white : Color.brandPrimary)
                    .overlay {
                        if !viewModel.isCurrentStepPassed {
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
}
