//
//  PersonalizationCacheService.swift
//  LearningSpeakingEnglish
//

import Foundation
import SwiftData

/// Service managing SwiftData persistence and cache retrieval for personalized vocabulary content.
enum PersonalizationCacheService {
    static let promptVersion = "mission-poc-v1"
    static let modelVersion = "foundation-model-default"

    static func key(for vocabulary: RecommendedVocabulary, domain: String) -> String {
        "\(vocabulary.word.lowercased())|\(domain.lowercased())|\(promptVersion)|\(modelVersion)"
    }

    static func content(
        from cache: PersonalizedVocabularyCache,
        vocabulary: RecommendedVocabulary
    ) -> PersonalizedVocabularyContent? {
        let indexes = cache.selectedDefinitionIndexesCSV
            .split(separator: ",")
            .compactMap { Int($0) }
        let definitions = indexes.compactMap { index in
            vocabulary.allDefinitions.indices.contains(index) ? vocabulary.allDefinitions[index] : nil
        }
        guard !definitions.isEmpty else { return nil }

        let generatedExamples: [[String]]
        if let data = cache.generatedExamplesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([[String]].self, from: data) {
            generatedExamples = decoded
        } else {
            generatedExamples = []
        }

        var translation: IndonesianVocabularyTranslation?
        if let data = cache.translationJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(CachedIndonesianTranslation.self, from: data) {
            translation = IndonesianVocabularyTranslation(
                word: decoded.word,
                partOfSpeech: decoded.partOfSpeech,
                definitions: decoded.definitions,
                examples: decoded.examples
            )
        }

        return PersonalizedVocabularyContent(
            vocabulary: vocabulary,
            definitions: definitions,
            generatedExamples: generatedExamples,
            translation: translation
        )
    }

    static func makeCache(
        from result: PersonalizationResult,
        vocabulary: RecommendedVocabulary,
        domain: String
    ) -> PersonalizedVocabularyCache? {
        guard result.status == .ready else { return nil }

        let allDefinitions = vocabulary.allDefinitions
        let indexes = result.content.definitions.compactMap { definition in
            allDefinitions.firstIndex(of: definition)
        }
        guard !indexes.isEmpty,
              let examplesData = try? JSONEncoder().encode(result.content.generatedExamples),
              let examplesJSON = String(data: examplesData, encoding: .utf8) else {
            return nil
        }

        let translationJSON: String
        if let translation = result.content.translation,
           let data = try? JSONEncoder().encode(CachedIndonesianTranslation(
               word: translation.word,
               partOfSpeech: translation.partOfSpeech,
               definitions: translation.definitions,
               examples: translation.examples
           )),
           let value = String(data: data, encoding: .utf8) {
            translationJSON = value
        } else {
            translationJSON = ""
        }

        return PersonalizedVocabularyCache(
            cacheKey: key(for: vocabulary, domain: domain),
            word: vocabulary.word,
            domain: domain,
            promptVersion: promptVersion,
            modelVersion: modelVersion,
            selectedDefinitionIndexesCSV: indexes.map(String.init).joined(separator: ","),
            generatedExamplesJSON: examplesJSON,
            translationJSON: translationJSON
        )
    }

    static func save(
        result: PersonalizationResult,
        vocabulary: RecommendedVocabulary,
        domain: String,
        in context: ModelContext
    ) {
        guard let cache = makeCache(from: result, vocabulary: vocabulary, domain: domain) else { return }

        if let existing = try? context.fetch(FetchDescriptor<PersonalizedVocabularyCache>()).first(where: { $0.cacheKey == cache.cacheKey }) {
            existing.selectedDefinitionIndexesCSV = cache.selectedDefinitionIndexesCSV
            existing.generatedExamplesJSON = cache.generatedExamplesJSON
            existing.translationJSON = cache.translationJSON
            existing.generatedAt = cache.generatedAt
        } else {
            context.insert(cache)
        }

        try? context.save()
    }
}
