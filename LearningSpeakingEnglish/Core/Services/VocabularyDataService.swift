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
}
