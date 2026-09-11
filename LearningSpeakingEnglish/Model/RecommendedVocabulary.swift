//
//  RecommendedVocabulary.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// The bundled dictionary record used by the recommendation and mission POC.
struct RecommendedVocabulary: Codable, Identifiable {
    let word: String
    let cefrLevel: String
    let partOfSpeech: String
    let subtlwf: Double?
    let frequencyRank: Int?
    let normalizedRank: Double
    let domain: [String]
    let pronunciation: RecommendedPronunciation?
    let definitions: [RecommendedDefinitionGroup]

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
