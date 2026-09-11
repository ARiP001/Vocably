//
//  ListView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

struct ListView: View {
    @Binding var session: LearningSession
    let selectedDomain: String

    @State private var vocabulary: [RecommendedVocabulary] = []
    @State private var rankedVocabulary: [RankedRecommendedVocabulary] = []
    @State private var searchText = ""

    private var filteredVocabulary: [RankedRecommendedVocabulary] {
        guard !searchText.isEmpty else { return rankedVocabulary }

        return rankedVocabulary.filter { item in
            item.vocabulary.word.localizedCaseInsensitiveContains(searchText) ||
            item.vocabulary.partOfSpeech.localizedCaseInsensitiveContains(searchText) ||
            item.vocabulary.allDefinitions.contains { definition in
                definition.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vocabulary.isEmpty {
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                        Text("Loading vocabulary…")
                            .font(.subheadRegular)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List( ) { item in
                        NavigationLink {
                            CuratedMissionDetailView(
                                vocabulary: item.vocabulary,
                                selectedDomain: selectedDomain
                            ) {
                                session.finishLearning(named: item.vocabulary.word)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack {
                                    Text(item.vocabulary.word)
                                        .font(.headlineRegular)
                                    Spacer()
                                    if isLearned(item.vocabulary) {
                                        Text("Learned")
                                            .font(.caption1Semibold)
                                            .foregroundStyle(Color.brandPrimary)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color.brandPrimary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }

                                HStack(spacing: 6) {
                                    Text(item.vocabulary.partOfSpeech)
                                    Text("•")
                                    Text(item.vocabulary.domain.isEmpty ? "General" : item.vocabulary.domain.joined(separator: ", "))
                                }
                                .font(.subheadRegular)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search vocabulary")
            .task {
                if vocabulary.isEmpty {
                    vocabulary = VocabularyData.load()
                }
                refreshRanking()
            }
            .onChange(of: selectedDomain) { _, _ in
                refreshRanking()
            }
        }
    }

    private func refreshRanking() {
        rankedVocabulary = RecommendationEngine.rank(
            vocabulary: vocabulary,
            selectedDomain: selectedDomain
        )
    }

    private func isLearned(_ vocabulary: RecommendedVocabulary) -> Bool {
        session.isLearned(word: vocabulary.word)
    }
}

#Preview {
    ListPreviewWrapper()
}

private struct ListPreviewWrapper: View {
    @State private var session = LearningSession.placeholder(dailyGoal: 3)

    var body: some View {
        ListView(session: $session, selectedDomain: "Technology")
    }
}
