//
//  ProgressPersistenceService.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation
import SwiftData

enum ProgressPersistenceService {
    static func resolveStore(
        from stores: [LearningProgressStore],
        in context: ModelContext
    ) -> LearningProgressStore {
        if let existing = stores.first(where: { $0.singletonKey == "main-progress" }) {
            return existing
        }

        let created = LearningProgressStore()
        context.insert(created)
        return created
    }

    static func restore(
        session: inout LearningSession,
        from stores: [LearningProgressStore],
        in context: ModelContext
    ) {
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
           let restoredIndex = session.vocabList.firstIndex(where: {
               $0.nameEN.caseInsensitiveCompare(store.currentVocabName) == .orderedSame
           }) {
            session.currentIndex = restoredIndex
        }
    }

    static func persist(
        session: LearningSession,
        to stores: [LearningProgressStore],
        in context: ModelContext
    ) {
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
}
