//
//  CuratedMissionDetailViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import Observation

@Observable
final class CuratedMissionDetailViewModel {
    var content: PersonalizedVocabularyContent
    var showFullDetails = false
    var showSpeakingPractice = false
    var personalizationStatus: PersonalizationStatus = .loading
    var showPersonalizationAlert = false

    init(vocabulary: RecommendedVocabulary) {
        self.content = .fallback(for: vocabulary)
    }

    var practiceSentences: [String] {
        let generated = content.generatedExamples.compactMap(\.first)
        let original = content.definitions.compactMap { $0.examples?.first }
        return Array((generated + original).prefix(2))
    }

    func loadPersonalizedContent(
        vocabulary: RecommendedVocabulary,
        selectedDomain: String,
        cachedContent: PersonalizedVocabularyContent?,
        onSaveCache: ((PersonalizationResult) -> Void)? = nil
    ) async {
        personalizationStatus = .loading
        if let cachedContent {
            content = cachedContent
            personalizationStatus = .ready
            return
        }

        let result = await VocabularyPersonalizationService.prepareDeduplicated(
            vocabulary: vocabulary,
            domain: selectedDomain
        )
        content = result.content
        personalizationStatus = result.status
        onSaveCache?(result)
        if result.status == .unavailable || result.status == .failed {
            showPersonalizationAlert = true
        }
    }

    func examples(at index: Int) -> [String] {
        guard content.generatedExamples.indices.contains(index) else { return [] }
        return content.generatedExamples[index]
    }

    func exampleTranslations(at index: Int) -> [String] {
        guard let translations = content.translation?.examples,
              translations.indices.contains(index) else { return [] }
        return translations[index]
    }

    func definitionTranslation(at index: Int) -> String? {
        guard let definitions = content.translation?.definitions,
              definitions.indices.contains(index) else { return nil }
        return definitions[index]
    }

    func speak(text: String, languageCode: String = "en-US") {
        SpeechService.speak(text, languageCode: languageCode)
    }
}
