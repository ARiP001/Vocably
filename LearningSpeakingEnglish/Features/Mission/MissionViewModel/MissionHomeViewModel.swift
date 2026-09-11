//
//  MissionHomeViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class MissionHomeViewModel {
    var vocabulary: [RecommendedVocabulary] = []
    var recommendedVocabulary: RecommendedVocabulary?
    var skippedWordIDs: Set<String> = []

    func displayName(for userName: String) -> String {
        AppDefaults.sanitizedName(userName)
    }

    func hasCompletedDailyTarget(session: LearningSession) -> Bool {
        session.dailyTargetCount > 0 && session.completedToday >= session.dailyTargetCount
    }

    func loadRecommendation(selectedDomain: String, session: LearningSession) {
        if vocabulary.isEmpty {
            vocabulary = VocabularyDataService.load()
        }
        recommendNext(excluding: nil, selectedDomain: selectedDomain, session: session)
    }

    func skipCurrentWord(selectedDomain: String, session: LearningSession) {
        guard let vocab = recommendedVocabulary else { return }
        skippedWordIDs.insert(vocab.id.lowercased())
        recommendNext(excluding: vocab.id, selectedDomain: selectedDomain, session: session)
    }

    func completeMission(
        word: String,
        wordID: String,
        selectedDomain: String,
        session: inout LearningSession
    ) {
        session.finishLearning(named: word)
        recommendNext(excluding: wordID, selectedDomain: selectedDomain, session: session)
    }

    func resetForDomain(selectedDomain: String, session: LearningSession) {
        skippedWordIDs.removeAll()
        recommendedVocabulary = nil
        loadRecommendation(selectedDomain: selectedDomain, session: session)
    }

    func recommendNext(excluding wordID: String?, selectedDomain: String, session: LearningSession) {
        let ranked = RecommendationService.rank(vocabulary: vocabulary, selectedDomain: selectedDomain)
        let learned = session.learnedWordNames

        // 1. First priority: Unlearned word that has not been skipped in this session
        if let next = ranked.first(where: { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            guard !skippedWordIDs.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }) {
            recommendedVocabulary = next.vocabulary
            return
        }

        // 2. Second priority: If all unlearned words in domain were skipped, reset skipped list and pick next
        if let next = ranked.first(where: { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }) {
            skippedWordIDs.removeAll()
            if let wordID { skippedWordIDs.insert(wordID.lowercased()) }
            recommendedVocabulary = next.vocabulary
            return
        }

        // 3. Fallback: If all words in domain are learned, show next available word excluding current
        recommendedVocabulary = ranked.first(where: {
            $0.vocabulary.word.caseInsensitiveCompare(wordID ?? "") != .orderedSame
        })?.vocabulary
    }

    func prefetchUpcomingVocabulary(
        selectedDomain: String,
        caches: [PersonalizedVocabularyCache],
        modelContext: ModelContext
    ) async {
        guard VocabularyPersonalizationService.isAvailable else { return }

        let ranked = RecommendationService.rank(
            vocabulary: vocabulary,
            selectedDomain: selectedDomain
        )
        let upcoming = Array(ranked.prefix(10))
        let cachedKeys = Set(caches.map(\.cacheKey))
        let cachedCount = upcoming.filter {
            cachedKeys.contains(PersonalizationCacheService.key(for: $0.vocabulary, domain: selectedDomain))
        }.count

        guard cachedCount < 5 else { return }

        var preparedKeys = cachedKeys
        for item in upcoming {
            if Task.isCancelled { return }

            let key = PersonalizationCacheService.key(for: item.vocabulary, domain: selectedDomain)
            guard !preparedKeys.contains(key) else { continue }

            let result = await VocabularyPersonalizationService.prepareDeduplicated(
                vocabulary: item.vocabulary,
                domain: selectedDomain
            )
            PersonalizationCacheService.save(
                result: result,
                vocabulary: item.vocabulary,
                domain: selectedDomain,
                in: modelContext
            )
            if result.status == .ready {
                preparedKeys.insert(key)
            }
        }
    }

    func speak(word: String, languageCode: String = "en-US") {
        SpeechService.speak(word, languageCode: languageCode)
    }
}
