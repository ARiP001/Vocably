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
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading vocabulary…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredVocabulary) { item in
                        NavigationLink {
                            CuratedMissionDetailView(
                                vocabulary: item.vocabulary,
                                selectedDomain: selectedDomain
                            ) {
                                session.finishLearning(named: item.vocabulary.word)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(item.vocabulary.word)
                                        .font(.headline)
                                    Spacer()
                                    Text(isLearned(item.vocabulary) ? "Learned" : item.vocabulary.cefrLevel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(isLearned(item.vocabulary) ? Color.appPrimary : .secondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background((isLearned(item.vocabulary) ? Color.appPrimary : Color.gray).opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                HStack(spacing: 6) {
                                    Text(item.vocabulary.partOfSpeech)
                                    Text("•")
                                    Text(item.vocabulary.domain.isEmpty ? "General" : item.vocabulary.domain.joined(separator: ", "))
                                }
                                .font(.subheadline)
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
        guard let legacyVocab = session.vocabList.first(where: {
            $0.nameEN.caseInsensitiveCompare(vocabulary.word) == .orderedSame
        }) else {
            return false
        }
        return session.learnedVocabIDs.contains(legacyVocab.id)
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
