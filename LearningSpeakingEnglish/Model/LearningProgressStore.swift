//
//  LearningProgressStore.swift
//  LearningSpeakingEnglish
//

import Foundation
import SwiftData

/// Penyimpanan persisten untuk riwayat dan kemajuan belajar pengguna antar sesi aplikasi.
@Model
final class LearningProgressStore {
    /// Kunci tetap untuk memastikan hanya ada satu data kemajuan tunggal (singleton) di container aplikasi.
    var singletonKey: String
    var learnedVocabNames: [String]
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
