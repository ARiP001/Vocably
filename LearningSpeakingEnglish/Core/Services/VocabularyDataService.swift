//
//  VocabularyDataService.swift
//  LearningSpeakingEnglish
//

import Foundation

/// Service responsible for loading bundled vocabulary definitions.
enum VocabularyDataService {
    static func load() -> [RecommendedVocabulary] {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            return []
        }

        do {
            return try JSONDecoder().decode([RecommendedVocabulary].self, from: Data(contentsOf: url))
        } catch {
            return []
        }
    }

    /// Creates an in-memory session populated from bundled vocabulary data.
    @MainActor
    static func createSession(dailyGoal: Int, interest: String = "General") -> LearningSession {
        let vocabulary = load().map(Vocab.init(recommendedVocabulary:))
        return LearningSession(
            dailyGoal: max(1, dailyGoal),
            vocabList: vocabulary,
            selectedInterest: interest
        )
    }
}
