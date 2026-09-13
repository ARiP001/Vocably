//
//  RecommendedVocabulary.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// Data kosakata kamus bawaan yang digunakan untuk sistem rekomendasi dan misi belajar.
struct RecommendedVocabulary: Codable, Identifiable {
    let word: String
    let cefrLevel: String
    let partOfSpeech: String
    /// Frekuensi kata SUBTLEX per satu juta kata (nilai lebih tinggi menandakan kata lebih sering digunakan dalam percakapan lisan).
    let subtlexFrequency: Double?
    let frequencyRank: Int?
    let normalizedRank: Double
    let domain: [String]
    let pronunciation: RecommendedPronunciation?
    let definitions: [RecommendedDefinitionGroup]

    enum CodingKeys: String, CodingKey {
        case word
        case cefrLevel
        case partOfSpeech
        case subtlexFrequency = "subtlwf"
        case frequencyRank
        case normalizedRank
        case domain
        case pronunciation
        case definitions
    }

    var id: String { word }

    var allDefinitions: [RecommendedDefinition] {
        definitions.flatMap(\.definitions)
    }
}

struct RecommendedPronunciation: Codable {
    let ipa: String?
}

struct RecommendedDefinitionGroup: Codable {
    let definitions: [RecommendedDefinition]
}

struct RecommendedDefinition: Codable, Hashable {
    let cefr: String?
    let label: String?
    let description: String?
    let examples: [String]?
}

struct RankedRecommendedVocabulary: Identifiable {
    let vocabulary: RecommendedVocabulary
    let score: Double

    var id: String { vocabulary.id }
}
