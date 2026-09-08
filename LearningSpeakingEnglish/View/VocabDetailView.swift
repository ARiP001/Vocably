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
                    VStack(spacing: 20) {
                        wordCard(vocab: vocab)
                        examplesCard(vocab: vocab)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
            } else {
                ContentUnavailableView("No Vocabulary", systemImage: "text.book.closed")
                    .padding(.top, 80)
            }

            bottomActionBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mission Detail")
        .navigationBarTitleDisplayMode(.inline)
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
                LearnVocabView(session: $session) {
                    showLearningFlow = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Daily Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(session.progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            RunnerProgressView(progress: session.progressValue)
                .frame(height: 15)
        }
        .padding(.horizontal, 6)
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func wordCard(vocab: Vocab) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vocab.nameEN)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isCurrentVocabLearned {
                        Text("Learned")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()

                Button("Skip") {
                    showSkipAlert = true
                }
                .font(.caption.weight(.semibold))
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
                    HStack(spacing: 8) {
                        Text(vocab.pronoun)
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .foregroundStyle(Color.appSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appSecondary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text(vocab.nameID)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 10) {
//                Text("Meaning")
//                    .font(.headline)

                Text("(\(vocab.wordTypeEN)) \(vocab.meaningEN)")
                    .foregroundStyle(.primary)

                Text("(\(vocab.wordTypeID)) \(vocab.meaningID)")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func examplesCard(vocab: Vocab) -> some View {
        let selectedExamples = vocab.examples(for: session.selectedInterest)

        return VStack(alignment: .leading, spacing: 14) {
            Text("Examples")
                .font(.headline)

            ForEach(Array(selectedExamples.enumerated()), id: \.element.id) { index, example in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.semibold))
                        Button {
                            SpeechHelper.speak(example.exampleEN, languageCode: "en-US")
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .frame(width: 28, height: 28)
                                .glassEffect()
                                .clipShape(Circle())
                                .foregroundStyle(Color.appSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(example.exampleEN)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(example.exampleID)
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bottomActionBar: some View {
        HStack(spacing: 10) {
//            NavigationLink {
//                ListView(session: session)
//            } label: {
//                Image(systemName: "list.bullet")
//                    .frame(width: 48, height: 48)
//                    .glassEffect()
//                    .clipShape(Circle())
//                    .foregroundStyle(Color.appPrimary)
//            }

            if isCurrentVocabLearned {
                NavigationLink {
                    CompareView(session: $session)
                } label: {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .frame(width: 48, height: 48)
                        .glassEffect()
                        .clipShape(Circle())
                        .foregroundStyle(Color.appSecondary)
                }
            }

            Button {
                showLearningFlow = true
            } label: {
                Text("Speak Now")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(Color(.systemGroupedBackground))
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
                    .fill(Color.appPrimary)
                    .frame(width: width * normalizedProgress, height: 6)

                Image(systemName: "figure.run")
                    .font(.caption.weight(.bold))
                    .offset(x: max(0, width * normalizedProgress - 9))

                HStack {
                    Spacer()
                    Image(systemName: "flag.fill")
                        .font(.caption.weight(.bold))
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
