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

    /// Looks up cached personalized content matching the vocabulary word and domain.
    static func findContent(
        for vocabulary: RecommendedVocabulary,
        domain: String,
        in caches: [PersonalizedVocabularyCache]
    ) -> PersonalizedVocabularyContent? {
        let cacheKey = key(for: vocabulary, domain: domain)
        guard let cache = caches.first(where: { $0.cacheKey == cacheKey }) else { return nil }
        return content(from: cache, vocabulary: vocabulary)
    }

    static func content(
        from cache: PersonalizedVocabularyCache,
        vocabulary: RecommendedVocabulary
    ) -> PersonalizedVocabularyContent? {
        let definitions = resolveDefinitions(indexes: cache.selectedDefinitionIndexes, in: vocabulary)
        guard !definitions.isEmpty else { return nil }

        return PersonalizedVocabularyContent(
            vocabulary: vocabulary,
            definitions: definitions,
            generatedExamples: decodeGeneratedExamples(from: cache.generatedExamplesJSON),
            translation: decodeTranslation(from: cache.translationJSON)
        )
    }

    static func makeCache(
        from result: PersonalizationResult,
        vocabulary: RecommendedVocabulary,
        domain: String
    ) -> PersonalizedVocabularyCache? {
        guard result.status == .ready else { return nil }

        let indexes = definitionIndexes(for: result.content.definitions, in: vocabulary)
        guard !indexes.isEmpty,
              let examplesJSON = encodeGeneratedExamples(result.content.generatedExamples) else {
            return nil
        }

        return PersonalizedVocabularyCache(
            cacheKey: key(for: vocabulary, domain: domain),
            word: vocabulary.word,
            domain: domain,
            promptVersion: promptVersion,
            modelVersion: modelVersion,
            selectedDefinitionIndexes: indexes,
            generatedExamplesJSON: examplesJSON,
            translationJSON: encodeTranslation(result.content.translation)
        )
    }

    static func save(
        result: PersonalizationResult,
        vocabulary: RecommendedVocabulary,
        domain: String,
        in context: ModelContext
    ) {
        guard let cache = makeCache(from: result, vocabulary: vocabulary, domain: domain) else { return }
        upsertCache(cache, in: context)
        try? context.save()
    }

    // MARK: - Private Helpers

    private static func resolveDefinitions(
        indexes: [Int],
        in vocabulary: RecommendedVocabulary
    ) -> [RecommendedDefinition] {
        let all = vocabulary.allDefinitions
        return indexes.compactMap { index in
            guard index >= 0, index < all.count else { return nil }
            return all[index]
        }
    }

    private static func decodeGeneratedExamples(from json: String) -> [[String]] {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([[String]].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func decodeTranslation(from json: String) -> IndonesianVocabularyTranslation? {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(CachedIndonesianTranslation.self, from: data) else {
            return nil
        }
        return IndonesianVocabularyTranslation(
            word: decoded.word,
            partOfSpeech: decoded.partOfSpeech,
            definitions: decoded.definitions,
            examples: decoded.examples
        )
    }

    private static func definitionIndexes(
        for definitions: [RecommendedDefinition],
        in vocabulary: RecommendedVocabulary
    ) -> [Int] {
        let all = vocabulary.allDefinitions
        return definitions.compactMap { all.firstIndex(of: $0) }
    }

    private static func encodeGeneratedExamples(_ examples: [[String]]) -> String? {
        guard let data = try? JSONEncoder().encode(examples) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func encodeTranslation(_ translation: IndonesianVocabularyTranslation?) -> String {
        guard let translation,
              let data = try? JSONEncoder().encode(CachedIndonesianTranslation(
                  word: translation.word,
                  partOfSpeech: translation.partOfSpeech,
                  definitions: translation.definitions,
                  examples: translation.examples
              )) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func upsertCache(_ cache: PersonalizedVocabularyCache, in context: ModelContext) {
        if let existing = try? context.fetch(FetchDescriptor<PersonalizedVocabularyCache>()).first(where: { $0.cacheKey == cache.cacheKey }) {
            existing.selectedDefinitionIndexes = cache.selectedDefinitionIndexes
            existing.generatedExamplesJSON = cache.generatedExamplesJSON
            existing.translationJSON = cache.translationJSON
            existing.generatedAt = cache.generatedAt
        } else {
            context.insert(cache)
        }
    }
}
