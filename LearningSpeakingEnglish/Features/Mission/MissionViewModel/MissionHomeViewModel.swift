//
//  MissionHomeViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
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

    /// Marks the given vocabulary mission as completed in the session and advances recommendation.
    func completeMission(
        for vocabulary: RecommendedVocabulary,
        selectedDomain: String,
        session: inout LearningSession
    ) {
        session.finishLearning(named: vocabulary.word)
        recommendNext(excluding: vocabulary.id, selectedDomain: selectedDomain, session: session)
    }

    func resetForDomain(selectedDomain: String, session: LearningSession) {
        skippedWordIDs.removeAll()
        recommendedVocabulary = nil
        loadRecommendation(selectedDomain: selectedDomain, session: session)
    }

    func recommendNext(excluding wordID: String?, selectedDomain: String, session: LearningSession) {
        let ranked = RecommendationService.rank(vocabulary: vocabulary, selectedDomain: selectedDomain)
        let learned = session.learnedWordNames

        if let next = findUnlearnedUnskipped(in: ranked, excluding: wordID, learned: learned) {
            recommendedVocabulary = next
            return
        }

        if let next = findUnlearned(in: ranked, excluding: wordID, learned: learned) {
            resetSkipped(keeping: wordID)
            recommendedVocabulary = next
            return
        }

        recommendedVocabulary = fallbackWord(in: ranked, excluding: wordID)
    }

    private func findUnlearnedUnskipped(
        in ranked: [RankedRecommendedVocabulary],
        excluding wordID: String?,
        learned: Set<String>
    ) -> RecommendedVocabulary? {
        ranked.first { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            guard !skippedWordIDs.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }?.vocabulary
    }

    private func findUnlearned(
        in ranked: [RankedRecommendedVocabulary],
        excluding wordID: String?,
        learned: Set<String>
    ) -> RecommendedVocabulary? {
        ranked.first { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }?.vocabulary
    }

    private func fallbackWord(
        in ranked: [RankedRecommendedVocabulary],
        excluding wordID: String?
    ) -> RecommendedVocabulary? {
        ranked.first {
            $0.vocabulary.word.caseInsensitiveCompare(wordID ?? "") != .orderedSame
        }?.vocabulary
    }

    private func resetSkipped(keeping wordID: String?) {
        skippedWordIDs.removeAll()
        if let wordID {
            skippedWordIDs.insert(wordID.lowercased())
        }
    }

    func upcomingVocabulary(for selectedDomain: String, limit: Int = 10) -> [RecommendedVocabulary] {
        let ranked = RecommendationService.rank(
            vocabulary: vocabulary,
            selectedDomain: selectedDomain
        )
        return Array(ranked.prefix(limit).map(\.vocabulary))
    }

    func speak(word: String, languageCode: String = "en-US") {
        SpeechService.speak(word, languageCode: languageCode)
    }
}
