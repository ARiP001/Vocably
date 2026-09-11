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
            .map { rankItem($0, for: selectedDomain) }
            .sorted { $0.score > $1.score }
    }

    private static func rankItem(
        _ word: RecommendedVocabulary,
        for selectedDomain: String
    ) -> RankedRecommendedVocabulary {
        let relevance = domainScore(for: word, domain: selectedDomain)
        let score = compositeScore(normalizedRank: word.normalizedRank, domainScore: relevance)
        return RankedRecommendedVocabulary(vocabulary: word, score: score)
    }

    private static func domainScore(for word: RecommendedVocabulary, domain: String) -> Double {
        if word.domain.isEmpty {
            return 0.5
        }
        if word.domain.contains(where: { $0.caseInsensitiveCompare(domain) == .orderedSame }) {
            return 1.0
        }
        return 0.0
    }

    private static func compositeScore(normalizedRank: Double, domainScore: Double) -> Double {
        (normalizedRank * 0.4) + (domainScore * 0.6)
    }
}
