//
//  MainTabViewModel.swift
//  LearningSpeakingEnglish
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class MainTabViewModel {
    var session: LearningSession
    private var hasRestoredProgress = false

    init(dailyGoal: Int, interest: String) {
        self.session = VocabularyDataService.createSession(dailyGoal: dailyGoal, interest: interest)
    }

    func updateDailyGoal(_ newGoal: Int) {
        session.dailyGoal = max(1, newGoal)
    }

    func updateInterest(_ newInterest: String) {
        session.selectedInterest = newInterest
    }

    func restoreProgressIfNeeded(stores: [LearningProgressStore], context: ModelContext) {
        guard !hasRestoredProgress else { return }
        hasRestoredProgress = true

        let store = resolveStore(from: stores, in: context)
        let learnedNames = Set(
            store.learnedVocabNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )

        let restoredLearnedIDs = session.vocabList
            .filter { learnedNames.contains($0.nameEN.lowercased()) }
            .map { $0.id }
        session.learnedVocabIDs = restoredLearnedIDs

        if !store.currentVocabName.isEmpty,
           let restoredIndex = session.vocabList.firstIndex(where: { $0.nameEN.caseInsensitiveCompare(store.currentVocabName) == .orderedSame }) {
            session.currentIndex = restoredIndex
        }
    }

    func persistProgress(stores: [LearningProgressStore], context: ModelContext) {
        guard hasRestoredProgress else { return }

        let store = resolveStore(from: stores, in: context)
        let learnedNames = session.vocabList
            .filter { session.learnedVocabIDs.contains($0.id) }
            .map { $0.nameEN }
        store.learnedVocabNames = learnedNames
        store.currentVocabName = session.currentVocab?.nameEN ?? ""

        do {
            try context.save()
        } catch {
            // Keep app usable even when persistence fails.
        }
    }

    private func resolveStore(from stores: [LearningProgressStore], in context: ModelContext) -> LearningProgressStore {
        if let existing = stores.first(where: { $0.singletonKey == "main-progress" }) {
            return existing
        }

        let created = LearningProgressStore()
        context.insert(created)
        return created
    }
}
