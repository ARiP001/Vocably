//
//  RecommendationService.swift
//  LearningSpeakingEnglish
//

import Foundation

/// Service responsible for scoring and ranking vocabulary based on domain relevance and frequency.
enum RecommendationService {
    static func rank(
        vocabulary: [RecommendedVocabulary],
        selectedDomain: String
    ) -> [RankedRecommendedVocabulary] {
        vocabulary
            .map { word in
                let domainScore: Double
                if word.domain.isEmpty {
                    domainScore = 0.5
                } else if word.domain.contains(where: { $0.caseInsensitiveCompare(selectedDomain) == .orderedSame }) {
                    domainScore = 1
                } else {
                    domainScore = 0
                }

                let score =
                    (word.normalizedRank * 0.4) +
                    (domainScore * 0.6)
                return RankedRecommendedVocabulary(vocabulary: word, score: score)
            }
            .sorted { $0.score > $1.score }
    }
}
