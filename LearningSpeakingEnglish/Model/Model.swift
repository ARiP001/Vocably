//
//  Model.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 22/04/26.
//

import SwiftUI

/// Discrete score buckets used across pronunciation feedback UI.
enum PronunciationScore {
    case perfect
    case almost
    case keepTrying
    case unrecognized

    var title: String {
        switch self {
        case .perfect:
            return "Great"
        case .almost:
            return "Almost"
        case .keepTrying:
            return "Keep trying"
        case .unrecognized:
            return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .perfect:
            return .green
        case .almost:
            return .orange
        case .keepTrying:
            return .red
        case .unrecognized:
            return .secondary
        }
    }
}

struct PronunciationResult {
    var recognizedText: String = ""
    var score: PronunciationScore = .unrecognized
    /// Overall Azure HundredMark score (0...100).
    var percentage: Double?
    /// Scores returned for each recognized word, in spoken order.
    var words: [PronunciationWordResult] = []
}

struct PronunciationWordResult: Identifiable {
    let id = UUID()
    let word: String
    let score: Double

    var color: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
}

/// Lightweight vocabulary representation used by LearningSession.
struct Vocab: Identifiable {
    let id: UUID = UUID()
    let nameEN: String
}

extension Vocab {
    init(recommendedVocabulary: RecommendedVocabulary) {
        self.init(nameEN: recommendedVocabulary.word)
    }
}

/// Runtime session state that powers mission progress and daily goals.
struct LearningSession {
    var dailyGoal: Int
    var vocabList: [Vocab]
    var selectedInterest: String = "General"
    var currentIndex: Int = 0
    var learnedVocabIDs: [UUID] = []

    /// Set of lowercase vocabulary names that have been marked as learned.
    var learnedWordNames: Set<String> {
        let learnedSet = Set(learnedVocabIDs)
        return Set(vocabList.filter { learnedSet.contains($0.id) }.map { $0.nameEN.lowercased() })
    }

    /// Checks whether a given vocabulary word has already been learned.
    func isLearned(word: String) -> Bool {
        learnedWordNames.contains(word.lowercased())
    }

    /// Safe daily target, clamped to available vocab count.
    var dailyTargetCount: Int {
        if vocabList.isEmpty {
            return 0
        }

        let safeGoal = max(1, dailyGoal)
        return min(safeGoal, vocabList.count)
    }

    /// Completed items limited by current daily target.
    var completedToday: Int {
        min(learnedVocabIDs.count, dailyTargetCount)
    }

    /// 0...1 progress value for progress bars.
    var progressValue: CGFloat {
        if dailyTargetCount == 0 {
            return 0
        }

        return CGFloat(completedToday) / CGFloat(dailyTargetCount)
    }

    var progressText: String {
        "\(completedToday)/\(dailyTargetCount)"
    }

    /// Currently active vocab from the session index.
    var currentVocab: Vocab? {
        if vocabList.isEmpty {
            return nil
        }

        return vocabList[currentIndex]
    }

    /// Marks current vocab as learned and advances to next unlearned vocab.
    mutating func finishCurrentLearning() {
        guard !vocabList.isEmpty else { return }

        let currentID = vocabList[currentIndex].id
        if !learnedVocabIDs.contains(currentID) {
            learnedVocabIDs.append(currentID)
        }

        moveToNextUnlearnedVocab()
    }

    /// Marks a vocabulary item learned by word name.
    mutating func finishLearning(named name: String) {
        guard let index = vocabList.firstIndex(where: { $0.nameEN.caseInsensitiveCompare(name) == .orderedSame }) else {
            return
        }

        currentIndex = index
        finishCurrentLearning()
    }

    /// Finds the next vocab that is not learned yet.
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

extension LearningSession {
    /// Creates in-memory session data from bundled vocabulary.
    @MainActor
    static func placeholder(dailyGoal: Int, interest: String = "General") -> LearningSession {
        let vocabulary = VocabularyData.load().map(Vocab.init(recommendedVocabulary:))
        return LearningSession(
            dailyGoal: max(1, dailyGoal),
            vocabList: vocabulary,
            selectedInterest: interest
        )
    }
}
