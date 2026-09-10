//
//  Vocab.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 13/04/26.
//

import SwiftUI

struct VocabDetailView: View {
    @Binding var session: LearningSession
    @Environment(\.dismiss) private var dismiss
    @State private var showSkipAlert = false
    @State private var showLearningFlow = false
    
    private var isCurrentVocabLearned: Bool {
        guard let currentID = session.currentVocab?.id else {
            return false
        }
        return session.learnedVocabIDs.contains(currentID)
    }

    var body: some View {
        VStack(spacing: 0) {
//            headerSection

            if let vocab = session.currentVocab {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        wordCard(vocab: vocab)
                        examplesCard(vocab: vocab)
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, 14)
                }
            } else {
                ContentUnavailableView("No Vocabulary", systemImage: "text.book.closed")
                    .padding(.top, 80)
            }

            bottomActionBar
        }
        .background(Color.bgPrimary)
        .navigationTitle("Mission Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Skip this word?", isPresented: $showSkipAlert) {
            Button("Cancel", role: .cancel) {
            }
            Button("Skip", role: .destructive) {
                session.skipCurrentVocab()
            }
        } message: {
            Text("You can learn this word later.")
        }
        .fullScreenCover(isPresented: $showLearningFlow) {
            NavigationStack {
                PersonalizedSpeakingPracticeView(
                    word: session.currentVocab?.nameEN ?? "Vocabulary",
                    sentences: session.currentExamples.map(\.exampleEN),
                    onFinished: {
                        session.finishCurrentLearning()
                        showLearningFlow = false
                        dismiss()
                    }
           ) }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Daily Progress")
                    .font(AppFont.caption1Regular)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(session.progressText)
                    .font(AppFont.caption1Semibold)
                    .foregroundStyle(Color.brandPrimary)
            }

            RunnerProgressView(progress: session.progressValue)
                .frame(height: 15)
        }
        .padding(.horizontal, 6)
        .padding(.horizontal)
        .padding(.top, Spacing.sm)
    }

    private func wordCard(vocab: Vocab) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vocab.nameEN)
                        .font(AppFont.largeTitleBold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isCurrentVocabLearned {
                        Text("Learned")
                            .font(AppFont.caption2Bold)
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brandPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()

                Button("Skip") {
                    showSkipAlert = true
                }
                .font(AppFont.caption1Semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.12))
                .clipShape(Capsule())
            }

            HStack {
                Button {
                    SpeechHelper.speak(vocab.nameEN, languageCode: "en-US")
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text(vocab.pronoun)
                            .font(AppFont.subheadMedium)
                        Image.speaker
                    }
                    .foregroundStyle(Color.brandSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brandSecondary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text(vocab.nameID)
                .font(AppFont.title3Bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("(\(vocab.wordTypeEN)) \(vocab.meaningEN)")
                    .font(AppFont.bodyRegular)
                    .foregroundStyle(.primary)

                Text("(\(vocab.wordTypeID)) \(vocab.meaningID)")
                    .font(AppFont.bodyRegular)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func examplesCard(vocab: Vocab) -> some View {
        let selectedExamples = vocab.examples(for: session.selectedInterest)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Examples")
                .font(AppFont.headlineRegular)

            ForEach(Array(selectedExamples.enumerated()), id: \.element.id) { index, example in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(AppFont.subheadSemibold)
                        Button {
                            SpeechHelper.speak(example.exampleEN, languageCode: "en-US")
                        } label: {
                            Image.speaker
                                .frame(width: 28, height: 28)
                                .glassEffect()
                                .clipShape(Circle())
                                .foregroundStyle(Color.brandSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(example.exampleEN)
                            .font(AppFont.bodyRegular)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(example.exampleID)
                            .font(AppFont.bodyRegular)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if index != selectedExamples.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var bottomActionBar: some View {
        HStack(spacing: 10) {
            Button {
                showLearningFlow = true
            } label: {
                Text("Speak Now")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brandPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(Color.bgPrimary)
    }
}

struct RunnerProgressView: View {
    var progress: CGFloat

    private var normalizedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 6)

                Capsule()
                    .fill(Color.brandPrimary)
                    .frame(width: width * normalizedProgress, height: 6)

                Image.run
                    .font(AppFont.caption1Bold)
                    .offset(x: max(0, width * normalizedProgress - 9))

                HStack {
                    Spacer()
                    Image.flag
                        .font(AppFont.caption1Bold)
                        .offset(x: 12)
                }
            }
        }
        .frame(height: 15)
    }
}

#Preview {
    NavigationStack {
        VocabDetailPreviewWrapper()
    }
}

private struct VocabDetailPreviewWrapper: View {
    @State private var session = LearningSession.placeholder(dailyGoal: 3)

    var body: some View {
        VocabDetailView(session: $session)
    }
}
