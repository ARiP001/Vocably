//
//  LearningSession.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// Representasi kosakata ringan yang digunakan dalam LearningSession.
struct Vocab: Identifiable {
    let id: UUID = UUID()
    let word: String
}

extension Vocab {
    init(recommendedVocabulary: RecommendedVocabulary) {
        self.init(word: recommendedVocabulary.word)
    }
}

/// State runtime sesi belajar yang mengelola progres misi dan target harian.
struct LearningSession {
    var dailyGoal: Int
    var vocabList: [Vocab] = []
    var selectedInterest: String = "General"
    var currentIndex: Int = 0
    var learnedVocabIDs: [UUID] = []

    var learnedWordNames: Set<String> {
        let learnedSet = Set(learnedVocabIDs)
        return Set(vocabList.filter { learnedSet.contains($0.id) }.map { $0.word.lowercased() })
    }

    func isLearned(word: String) -> Bool {
        learnedWordNames.contains(word.lowercased())
    }

    /// Target harian yang aman, dibatasi oleh jumlah kosakata yang tersedia.
    var dailyTargetCount: Int {
        guard !vocabList.isEmpty else { return 0 }
        return min(max(1, dailyGoal), vocabList.count)
    }

    /// Jumlah kata yang telah diselesaikan hari ini, dibatasi oleh target harian saat ini.
    var completedToday: Int {
        min(learnedVocabIDs.count, dailyTargetCount)
    }

    /// Nilai progres 0...1 untuk tampilan progress bar.
    var progressValue: Double {
        guard dailyTargetCount > 0 else { return 0 }
        return Double(completedToday) / Double(dailyTargetCount)
    }

    var progressText: String {
        "\(completedToday)/\(dailyTargetCount)"
    }

    /// Kosakata aktif saat ini berdasarkan indeks sesi.
    var currentVocab: Vocab? {
        guard currentIndex >= 0, currentIndex < vocabList.count else { return nil }
        return vocabList[currentIndex]
    }

    /// Menandai kosakata saat ini sebagai telah dipelajari dan berpindah ke kosakata berikutnya.
    mutating func finishCurrentLearning() {
        guard currentIndex >= 0, currentIndex < vocabList.count else { return }
        let currentID = vocabList[currentIndex].id

        if !learnedVocabIDs.contains(currentID) {
            learnedVocabIDs.append(currentID)
        }

        moveToNextUnlearnedVocab()
    }

    /// Menandai kosakata sebagai telah dipelajari berdasarkan nama kata.
    mutating func finishLearning(named name: String) {
        guard let index = vocabList.firstIndex(where: { $0.word.caseInsensitiveCompare(name) == .orderedSame }) else {
            return
        }

        currentIndex = index
        finishCurrentLearning()
    }

    /// Menemukan dan berpindah ke kosakata berikutnya yang belum dipelajari.
    mutating func moveToNextUnlearnedVocab() {
        guard !vocabList.isEmpty else { return }

        if learnedVocabIDs.count >= vocabList.count {
            currentIndex = 0
            return
        }

        var nextIndex = (currentIndex + 1) % vocabList.count

        while learnedVocabIDs.contains(vocabList[nextIndex].id) {
            nextIndex = (nextIndex + 1) % vocabList.count
        }

        currentIndex = nextIndex
    }
}

