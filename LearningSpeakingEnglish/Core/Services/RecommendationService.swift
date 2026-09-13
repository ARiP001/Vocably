//
//  RecommendationService.swift
//  LearningSpeakingEnglish
//

import Foundation

/// Layanan untuk menghitung skor dan memperingkat kosakata berdasarkan relevansi domain minat serta frekuensi penggunaan.
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
        // Kosakata umum tanpa domain spesifik diberi bobot netral (0.5)
        // agar kata-kata dasar tetap dapat ditemukan saat kata khusus domain telah habis dipelajari.
        if word.domain.isEmpty {
            return 0.5
        }
        if word.domain.contains(where: { $0.caseInsensitiveCompare(domain) == .orderedSame }) {
            return 1.0
        }
        return 0.0
    }

    private static func compositeScore(normalizedRank: Double, domainScore: Double) -> Double {
        // Berikan bobot lebih tinggi pada relevansi domain (60%) dibanding frekuensi korpus (40%)
        // agar misi terasa terpersonalisasi dengan minat pengguna namun tetap menggunakan kata yang lazim.
        (normalizedRank * 0.4) + (domainScore * 0.6)
    }
}
