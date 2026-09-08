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
}

/// Stores recording URLs for the 3 learning steps of one vocab.
struct LearningRecording {
    var vocabURL: URL?
    var sentence1URL: URL?
    var sentence2URL: URL?
}

struct Example: Identifiable {
    let id: UUID = UUID()
    let exampleEN: String
    let exampleID: String
}

/// Core vocab model including interest-specific example sets.
struct Vocab: Identifiable {
    let id: UUID = UUID()
    let nameEN: String
    let pronoun: String
    let nameID: String
    let wordTypeEN: String
    let wordTypeID: String
    let meaningEN: String
    let meaningID: String
    let exampleListGeneral: [Example]
    let exampleListCode: [Example]
    let exampleListDesign: [Example]

    /// Returns examples based on selected user interest.
    func examples(for interest: String) -> [Example] {
        let normalizedInterest = interest.lowercased()

        if normalizedInterest == "code" {
            return exampleListCode
        }

        if normalizedInterest == "design" {
            return exampleListDesign
        }

        return exampleListGeneral
    }
}

/// Compatibility projection for the legacy speaking views.
/// The JSON record remains the source of truth; this projection exists until
/// those views are migrated to RecommendedVocabulary directly.
extension Vocab {
    init(recommendedVocabulary: RecommendedVocabulary) {
        let definitions = recommendedVocabulary.allDefinitions
        let firstDefinition = definitions.first
        let examples = (firstDefinition?.examples ?? []).map {
            Example(exampleEN: $0, exampleID: "")
        }

        self.init(
            nameEN: recommendedVocabulary.word,
            pronoun: recommendedVocabulary.pronunciation?.ipa ?? "",
            nameID: "",
            wordTypeEN: recommendedVocabulary.partOfSpeech,
            wordTypeID: "",
            meaningEN: firstDefinition?.description ?? "",
            meaningID: "",
            exampleListGeneral: examples,
            exampleListCode: examples,
            exampleListDesign: examples
        )
    }
}

struct Profile {
    let id: UUID = UUID()
    let name: String
    let interest: [String] = ["General", "Code", "Design"]
    let numberOfVocab: Int
}

/// Runtime session state that powers mission, learning flow, and progress.
struct LearningSession {
    var dailyGoal: Int
    var vocabList: [Vocab]
    var selectedInterest: String = "General"
    var currentIndex: Int = 0
    var learnedVocabIDs: [UUID] = []
    var recordingsByVocabID: [UUID: LearningRecording] = [:]

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

    /// Current vocab examples filtered by selected interest.
    var currentExamples: [Example] {
        guard let vocab = currentVocab else {
            return []
        }

        return vocab.examples(for: selectedInterest)
    }

    /// Skips current vocab and moves to next item cyclically.
    mutating func skipCurrentVocab() {
        if vocabList.isEmpty {
            return
        }

        currentIndex = (currentIndex + 1) % vocabList.count
    }

    /// Marks current vocab as learned and advances to next unlearned vocab.
    mutating func finishCurrentLearning() {
        if vocabList.isEmpty {
            return
        }

        let currentID = vocabList[currentIndex].id
        if !learnedVocabIDs.contains(currentID) {
            learnedVocabIDs.append(currentID)
        }

        moveToNextUnlearnedVocab()
    }

    /// Marks a JSON vocabulary item learned, even when it was opened from a
    /// ranked recommendation rather than the session's current index.
    mutating func finishLearning(named name: String) {
        guard let index = vocabList.firstIndex(where: { $0.nameEN.caseInsensitiveCompare(name) == .orderedSame }) else {
            return
        }

        currentIndex = index
        finishCurrentLearning()
    }

    /// Saves recording URL for a specific learning step (1, 2, or 3).
    mutating func saveRecording(forStep step: Int, fileURL: URL) {
        guard !vocabList.isEmpty else {
            return
        }

        let currentID = vocabList[currentIndex].id
        var recording = recordingsByVocabID[currentID] ?? LearningRecording()

        if step == 1 {
            recording.vocabURL = fileURL
        } else if step == 2 {
            recording.sentence1URL = fileURL
        } else if step == 3 {
            recording.sentence2URL = fileURL
        }

        recordingsByVocabID[currentID] = recording
    }

    /// Reads stored recording URL for a specific step of current vocab.
    func recordingURL(forStep step: Int) -> URL? {
        guard let vocab = currentVocab else {
            return nil
        }

        guard let recording = recordingsByVocabID[vocab.id] else {
            return nil
        }

        if step == 1 {
            return recording.vocabURL
        }

        if step == 2 {
            return recording.sentence1URL
        }

        if step == 3 {
            return recording.sentence2URL
        }

        return nil
    }

    /// Finds the next vocab that is not learned yet.
    mutating func moveToNextUnlearnedVocab() {
        if vocabList.isEmpty {
            return
        }

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
    /// Creates in-memory session data from placeholder database.
    static func placeholder(dailyGoal: Int, interest: String = "General") -> LearningSession {
        let vocabulary = VocabularyData.load().map(Vocab.init(recommendedVocabulary:))
        LearningSession(
            dailyGoal: max(1, dailyGoal),
            vocabList: vocabulary,
            selectedInterest: interest
        )
    }
}
