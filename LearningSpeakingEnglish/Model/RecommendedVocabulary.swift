//
//  RecommendedVocabulary.swift
//  LearningSpeakingEnglish
//

import Foundation
import FoundationModels
import SwiftData

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

/// The curated content shown by the three-card mission screen.
struct PersonalizedVocabularyContent {
    let vocabulary: RecommendedVocabulary
    let definitions: [RecommendedDefinition]
    let generatedExamples: [[String]]
    let translation: IndonesianVocabularyTranslation?

    static func fallback(for vocabulary: RecommendedVocabulary) -> PersonalizedVocabularyContent {
        PersonalizedVocabularyContent(
            vocabulary: vocabulary,
            definitions: Array(vocabulary.allDefinitions.prefix(2)),
            generatedExamples: [],
            translation: nil
        )
    }
}

enum PersonalizationStatus: Equatable {
    case loading
    case ready
    case unavailable
    case failed
}

struct PersonalizationResult {
    let content: PersonalizedVocabularyContent
    let status: PersonalizationStatus
}

/// SwiftData cache for content generated from the bundled dictionary record.
@Model
final class PersonalizedVocabularyCache {
    var cacheKey: String
    var word: String
    var domain: String
    var promptVersion: String
    var modelVersion: String
    var selectedDefinitionIndexesCSV: String
    var generatedExamplesJSON: String
    var translationJSON: String
    var generatedAt: Date

    init(
        cacheKey: String,
        word: String,
        domain: String,
        promptVersion: String,
        modelVersion: String,
        selectedDefinitionIndexesCSV: String,
        generatedExamplesJSON: String,
        translationJSON: String,
        generatedAt: Date = .now
    ) {
        self.cacheKey = cacheKey
        self.word = word
        self.domain = domain
        self.promptVersion = promptVersion
        self.modelVersion = modelVersion
        self.selectedDefinitionIndexesCSV = selectedDefinitionIndexesCSV
        self.generatedExamplesJSON = generatedExamplesJSON
        self.translationJSON = translationJSON
        self.generatedAt = generatedAt
    }
}

struct CachedIndonesianTranslation: Codable {
    let word: String
    let partOfSpeech: String
    let definitions: [String]
    let examples: [[String]]
}

@Generable
struct DefinitionSelection {
    @Guide(description: "Index of the most general and commonly useful definition.")
    let generalIndex: Int

    @Guide(description: "Index of the definition most relevant to the user's domain. If none is relevant, select another generally useful definition.")
    let secondaryIndex: Int
}

@Generable
struct GeneratedExamples {
    @Guide(description: "Exactly two short, natural example sentences that use the word and demonstrate the supplied definition.")
    let examples: [String]
}

@Generable
struct IndonesianVocabularyTranslation {
    @Guide(description: "Natural Indonesian translation of the English word.")
    let word: String

    @Guide(description: "Natural Indonesian translation of the part of speech.")
    let partOfSpeech: String

    @Guide(description: "Indonesian translations of the selected definitions, in the same order.")
    let definitions: [String]

    @Guide(description: "Indonesian translations of generated examples. Keep the same nested order as the English examples.")
    let examples: [[String]]
}
