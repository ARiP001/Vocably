//
//  PersonalizationModels.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation
import FoundationModels

/// Konten terkurasi yang ditampilkan pada layar detail misi 3-kartu.
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
