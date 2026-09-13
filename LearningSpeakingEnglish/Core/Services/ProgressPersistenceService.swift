//
//  ProgressPersistenceService.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation
import SwiftData

/// Layanan untuk menyinkronkan dan memulihkan kemajuan sesi belajar pengguna ke penyimpanan SwiftData.
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
        let learnedNames = normalizedLearnedNames(from: store)

        session.learnedVocabIDs = restoredLearnedIDs(for: session, matching: learnedNames)
        if let restoredIndex = restoredCurrentIndex(for: session, targetName: store.currentVocabName) {
            session.currentIndex = restoredIndex
        }
    }

    static func persist(
        session: LearningSession,
        to stores: [LearningProgressStore],
        in context: ModelContext
    ) {
        let store = resolveStore(from: stores, in: context)
        store.learnedVocabNames = learnedVocabNames(from: session)
        store.currentVocabName = session.currentVocab?.word ?? ""

        do {
            try context.save()
        } catch {
            print("[ProgressPersistenceService] Failed to persist progress: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private static func normalizedLearnedNames(from store: LearningProgressStore) -> Set<String> {
        Set(
            store.learnedVocabNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    private static func restoredLearnedIDs(
        for session: LearningSession,
        matching learnedNames: Set<String>
    ) -> [UUID] {
        session.vocabList
            .filter { learnedNames.contains($0.word.lowercased()) }
            .map { $0.id }
    }

    private static func restoredCurrentIndex(
        for session: LearningSession,
        targetName: String
    ) -> Int? {
        guard !targetName.isEmpty else { return nil }
        return session.vocabList.firstIndex {
            $0.word.caseInsensitiveCompare(targetName) == .orderedSame
        }
    }

    private static func learnedVocabNames(from session: LearningSession) -> [String] {
        session.vocabList
            .filter { session.learnedVocabIDs.contains($0.id) }
            .map { $0.word }
    }
}
