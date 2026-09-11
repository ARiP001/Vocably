//
//  LearningProgressStore.swift
//  LearningSpeakingEnglish
//

import Foundation
import SwiftData

/// Persistent store for user learning progress across app launches.
@Model
final class LearningProgressStore {
    /// Fixed key so we only keep one progress record.
    var singletonKey: String
    /// Vocabulary names marked as learned.
    var learnedVocabNames: [String]
    /// Name of vocab currently selected in mission flow.
    var currentVocabName: String

    init(
        singletonKey: String = "main-progress",
        learnedVocabNames: [String] = [],
        currentVocabName: String = ""
    ) {
        self.singletonKey = singletonKey
        self.learnedVocabNames = learnedVocabNames
        self.currentVocabName = currentVocabName
    }
}
