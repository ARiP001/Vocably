//
//  SpeakingPracticeSummaryView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

struct SpeakingPracticeSummaryView: View {
    let viewModel: SpeakingPracticeViewModel
    let onFinish: () -> Void

    var body: some View {
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

                        EvaluatedPromptText(evaluatedWords: viewModel.evaluatedWords(prompt: viewModel.prompts[index], result: viewModel.results[index]))
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

                PrimaryButton(title: "Finish") {
                    viewModel.finishPractice()
                    onFinish()
                }
            }
            .padding()
        }
        .background(Color.bgPrimary)
        .navigationTitle("Practice Result")
        .navigationBarTitleDisplayMode(.inline)
    }
}
