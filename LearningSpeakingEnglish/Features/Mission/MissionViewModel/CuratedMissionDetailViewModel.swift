//
//  CuratedMissionDetailViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import SwiftData
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
        caches: [PersonalizedVocabularyCache],
        modelContext: ModelContext
    ) async {
        personalizationStatus = .loading
        let cacheKey = PersonalizationCacheService.key(for: vocabulary, domain: selectedDomain)
        if let cache = caches.first(where: { $0.cacheKey == cacheKey }),
           let cachedContent = PersonalizationCacheService.content(from: cache, vocabulary: vocabulary) {
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
        PersonalizationCacheService.save(
            result: result,
            vocabulary: vocabulary,
            domain: selectedDomain,
            in: modelContext
        )
        if result.status == .unavailable || result.status == .failed {
            showPersonalizationAlert = true
        }
    }

    func speak(text: String, languageCode: String = "en-US") {
        SpeechService.speak(text, languageCode: languageCode)
    }
}
