//
//  CompareView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 18/04/26.
//

import SwiftUI

struct CompareView: View {
    @Binding var session: LearningSession
    @Environment(\.dismiss) private var dismiss
    var onFlowFinished: (() -> Void)? = nil
    @State private var wordResult = PronunciationResult()
    @State private var sentence1Result = PronunciationResult()
    @State private var sentence2Result = PronunciationResult()

    private var currentWord: String {
        session.currentVocab?.nameEN ?? "Vocabulary"
    }

    private var currentSentence: String {
        session.currentExamples.first?.exampleEN ?? "No sentence available."
    }

    private var secondSentence: String {
        let examples = session.currentExamples
        guard examples.indices.contains(1) else {
            return "No second sentence available."
        }
        return examples[1].exampleEN
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    compareHeader
                    CompareSection(
                        title: "Word",
                        content: currentWord,
                        sourceLabel: "Reference",
                        attemptLabel: "Your attempt",
                        score: wordResult.score,
                        percentage: wordResult.percentage,
                        recognizedText: wordResult.recognizedText,
                        isAnalyzing: false,
                        onPlayReference: {
                            SpeechHelper.speak(currentWord, languageCode: "en-US")
                        },
                        onPlayAttempt: {
                            if let url = session.recordingURL(forStep: 1) {
                                RecordingPlaybackHelper.play(url: url)
                            } else {
                                SpeechHelper.speak(currentWord, languageCode: "en-US")
                            }
                        },
                    )
                    CompareSection(
                        title: "Sentence 1",
                        content: currentSentence,
                        sourceLabel: "Reference",
                        attemptLabel: "Your attempt",
                        score: sentence1Result.score,
                        percentage: sentence1Result.percentage,
                        recognizedText: sentence1Result.recognizedText,
                        isAnalyzing: false,
                        onPlayReference: {
                            SpeechHelper.speak(currentSentence, languageCode: "en-US")
                        },
                        onPlayAttempt: {
                            if let url = session.recordingURL(forStep: 2) {
                                RecordingPlaybackHelper.play(url: url)
                            } else {
                                SpeechHelper.speak(currentSentence, languageCode: "en-US")
                            }
                        },
                    )
                    CompareSection(
                        title: "Sentence 2",
                        content: secondSentence,
                        sourceLabel: "Reference",
                        attemptLabel: "Your attempt",
                        score: sentence2Result.score,
                        percentage: sentence2Result.percentage,
                        recognizedText: sentence2Result.recognizedText,
                        isAnalyzing: false,
                        onPlayReference: {
                            SpeechHelper.speak(secondSentence, languageCode: "en-US")
                        },
                        onPlayAttempt: {
                            if let url = session.recordingURL(forStep: 3) {
                                RecordingPlaybackHelper.play(url: url)
                            } else {
                                SpeechHelper.speak(secondSentence, languageCode: "en-US")
                            }
                        },
                    )
                    Spacer(minLength: 8)
                    
                    Button {
                        session.finishCurrentLearning()
                        if let onFlowFinished {
                            onFlowFinished()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Finish")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Let's Compare")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            wordResult = session.pronunciationResult(forStep: 1)
            sentence1Result = session.pronunciationResult(forStep: 2)
            sentence2Result = session.pronunciationResult(forStep: 3)
        }
    }
    private var compareHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.headline)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 36, height: 36)
                .background(Color.appSecondary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Final check")
                    .font(.headline)
                Text("Listen and compare before you finish")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

}

struct CompareSection: View {
    var title: String
    var content: String
    var sourceLabel: String
    var attemptLabel: String
    var score: PronunciationScore
    var percentage: Double?
    var recognizedText: String
    var isAnalyzing: Bool
    var onPlayReference: () -> Void = {}
    var onPlayAttempt: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .fixedSize(horizontal: false, vertical: true)

                Text(content)
                .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    onPlayReference()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text(sourceLabel)
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.appPrimary)
                }
                Button {
                    onPlayAttempt()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                        Text(attemptLabel)
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
                }

//                Image(systemName: "checkmark.circle.fill")
//                    .font(.title3)
//                    .foregroundStyle(Color.appPrimary)
//                    .frame(width: 44, height: 44)
            }

            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(score.color)
                        .frame(width: 8, height: 8)
                    Text(score.title + (percentage.map { " · PronScore: \(Int($0.rounded()))/100" } ?? ""))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(score.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(score.color.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                Text(isAnalyzing ? "Checking..." : (percentage == nil ? "Not checked" : "Already checked"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if !recognizedText.isEmpty {
                Text("Detected: \(recognizedText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview{
    NavigationStack {
        CompareView(session: .constant(LearningSession.placeholder(dailyGoal: 3)))
    }
}
