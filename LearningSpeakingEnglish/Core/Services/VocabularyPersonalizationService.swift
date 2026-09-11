//
//  VocabularyPersonalizationService.swift
//  LearningSpeakingEnglish
//

import Foundation
import FoundationModels

/// Runs the on-device Foundation Model personalization pipeline and returns fallback content if unavailable.
@MainActor
enum VocabularyPersonalizationService {
    private static var inFlight: [String: Task<PersonalizationResult, Never>] = [:]
    private static var failedThisSession = false

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    static func prepareDeduplicated(
        vocabulary: RecommendedVocabulary,
        domain: String
    ) async -> PersonalizationResult {
        let key = PersonalizationCacheService.key(for: vocabulary, domain: domain)
        if failedThisSession {
            return PersonalizationResult(
                content: .fallback(for: vocabulary),
                status: .failed
            )
        }
        if let existing = inFlight[key] {
            return await existing.value
        }

        let task = Task { @MainActor in
            await prepare(vocabulary: vocabulary, domain: domain)
        }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        if result.status == .unavailable || result.status == .failed {
            failedThisSession = true
        }
        return result
    }

    static func prepare(
        vocabulary: RecommendedVocabulary,
        domain: String
    ) async -> PersonalizationResult {
        guard isAvailable else {
            return PersonalizationResult(
                content: .fallback(for: vocabulary),
                status: .unavailable
            )
        }

        let selectedDefinitions = await selectDefinitions(for: vocabulary, domain: domain)
        var generatedExamples: [[String]] = []

        for definition in selectedDefinitions {
            generatedExamples.append(await generateDomainExamples(
                word: vocabulary.word,
                definition: definition,
                domain: domain
            ))
        }

        let translation = await translate(
            vocabulary: vocabulary,
            definitions: selectedDefinitions,
            generatedExamples: generatedExamples
        )

        let content = PersonalizedVocabularyContent(
            vocabulary: vocabulary,
            definitions: selectedDefinitions,
            generatedExamples: generatedExamples,
            translation: translation
        )
        let hasGeneratedContent = translation != nil || generatedExamples.contains(where: { !$0.isEmpty })

        return PersonalizationResult(
            content: content,
            status: hasGeneratedContent ? .ready : .failed
        )
    }

    private static func selectDefinitions(
        for vocabulary: RecommendedVocabulary,
        domain: String
    ) async -> [RecommendedDefinition] {
        let definitions = vocabulary.allDefinitions
        guard definitions.count > 2, SystemLanguageModel.default.isAvailable else {
            return Array(definitions.prefix(2))
        }

        let definitionText = definitions.enumerated().map { index, definition in
            "\(index): \(definition.description ?? "")"
        }.joined(separator: "\n")
        let domainInstruction = domain == "General"
            ? "Select the two most generally useful meanings."
            : "Select one generally useful meaning and one meaning relevant to the user's domain. If none is relevant, select another generally useful meaning."

        let prompt = """
        You select dictionary definitions for an English language-learning app.

        Word: \(vocabulary.word)
        User domain: \(domain)
        Definitions:
        \(definitionText)

        \(domainInstruction)
        Return exactly two different valid indexes. Preserve the original definitions; do not rewrite them.
        """

        do {
            let response = try await LanguageModelSession().respond(to: prompt, generating: DefinitionSelection.self)
            let selection = response.content
            guard definitions.indices.contains(selection.generalIndex),
                  definitions.indices.contains(selection.secondaryIndex),
                  selection.generalIndex != selection.secondaryIndex else {
                return Array(definitions.prefix(2))
            }
            return [definitions[selection.generalIndex], definitions[selection.secondaryIndex]]
        } catch {
            return Array(definitions.prefix(2))
        }
    }

    private static func generateDomainExamples(
        word: String,
        definition: RecommendedDefinition,
        domain: String
    ) async -> [String] {
        guard SystemLanguageModel.default.isAvailable,
              let description = definition.description,
              !description.isEmpty else {
            return []
        }

        let prompt = """
        Generate exactly two short English example sentences for a language-learning app.

        Word: \(word)
        Definition: \(description)
        User domain: \(domain)

        Use the word naturally, clearly demonstrate this definition, keep each sentence suitable for a learner, and return only the two sentences.
        """

        do {
            let response = try await LanguageModelSession().respond(to: prompt, generating: GeneratedExamples.self)
            return Array(response.content.examples.prefix(2))
        } catch {
            return []
        }
    }

    private static func translate(
        vocabulary: RecommendedVocabulary,
        definitions: [RecommendedDefinition],
        generatedExamples: [[String]]
    ) async -> IndonesianVocabularyTranslation? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let definitionText = definitions.map { $0.description ?? "" }.joined(separator: "\n")
        let exampleText = generatedExamples.enumerated().map { index, examples in
            "Definition \(index + 1): \(examples.joined(separator: " | "))"
        }.joined(separator: "\n")
        let prompt = """
        Translate this English learning content into natural Indonesian. Preserve the English meaning and return translations in exactly the supplied definition and example order.

        Word: \(vocabulary.word)
        Part of speech: \(vocabulary.partOfSpeech)
        Definitions:
        \(definitionText)
        Generated examples:
        \(exampleText)
        """

        do {
            return try await LanguageModelSession().respond(to: prompt, generating: IndonesianVocabularyTranslation.self).content
        } catch {
            return nil
        }
    }
}
