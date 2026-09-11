//
//  VocabListViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import Observation

@Observable
final class VocabListViewModel {
    var vocabulary: [RecommendedVocabulary] = []
    var rankedVocabulary: [RankedRecommendedVocabulary] = []
    var searchText = ""

    var filteredVocabulary: [RankedRecommendedVocabulary] {
        guard !searchText.isEmpty else { return rankedVocabulary }

        return rankedVocabulary.filter { item in
            item.vocabulary.word.localizedCaseInsensitiveContains(searchText) ||
            item.vocabulary.partOfSpeech.localizedCaseInsensitiveContains(searchText) ||
            item.vocabulary.allDefinitions.contains { definition in
                definition.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    func loadVocabulary(selectedDomain: String) {
        if vocabulary.isEmpty {
            vocabulary = VocabularyData.load()
        }
        refreshRanking(selectedDomain: selectedDomain)
    }

    func refreshRanking(selectedDomain: String) {
        rankedVocabulary = RecommendationEngine.rank(
            vocabulary: vocabulary,
            selectedDomain: selectedDomain
        )
    }

    func isLearned(_ vocabulary: RecommendedVocabulary, session: LearningSession) -> Bool {
        session.isLearned(word: vocabulary.word)
    }

    func finishLearning(named word: String, session: inout LearningSession) {
        session.finishLearning(named: word)
    }
}
