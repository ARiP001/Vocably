//
//  ListView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

/// Screen displaying searchable and ranked vocabulary list.
struct VocabListView: View {
    @Binding var session: LearningSession
    let selectedDomain: String

    @State private var viewModel = VocabListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.vocabulary.isEmpty {
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                        Text("Loading vocabulary…")
                            .font(.subheadRegular)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredVocabulary) { item in
                        NavigationLink {
                            CuratedMissionDetailView(
                                vocabulary: item.vocabulary,
                                selectedDomain: selectedDomain
                            ) {
                                viewModel.finishLearning(named: item.vocabulary.word, session: &session)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack {
                                    Text(item.vocabulary.word)
                                        .font(.headlineRegular)
                                    Spacer()
                                    if viewModel.isLearned(item.vocabulary, session: session) {
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
            .searchable(text: $viewModel.searchText, prompt: "Search vocabulary")
            .task {
                viewModel.loadVocabulary(selectedDomain: selectedDomain)
            }
            .onChange(of: selectedDomain) { _, _ in
                viewModel.refreshRanking(selectedDomain: selectedDomain)
            }
        }
    }
}

/// Backward compatibility alias for VocabListView.
typealias ListView = VocabListView

#Preview {
    ListPreviewWrapper()
}

private struct ListPreviewWrapper: View {
    @State private var session = VocabularyDataService.createSession(dailyGoal: 3)

    var body: some View {
        VocabListView(session: $session, selectedDomain: "Technology")
    }
}
