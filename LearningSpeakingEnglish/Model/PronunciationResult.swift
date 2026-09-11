//
//  PronunciationResult.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// Discrete score buckets used across pronunciation feedback.
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
}

/// Evaluation tier for an individual word in a practice prompt.
enum WordAccuracy {
    case unassessed
    case accurate
    case acceptable
    case poor

    init(score: Double) {
        switch score {
        case 80...:
            self = .accurate
        case 60..<80:
            self = .acceptable
        default:
            self = .poor
        }
    }
}

/// An evaluated word token ready for presentation rendering.
struct EvaluatedWord: Identifiable {
    let id = UUID()
    let word: String
    let accuracy: WordAccuracy
}

/// Overall speech recognition transcript and score assessment.
struct PronunciationResult {
    var recognizedText: String = ""
    var score: PronunciationScore = .unrecognized
    /// Overall Azure HundredMark score (0...100).
    var percentage: Double?
    /// Scores returned for each recognized word, in spoken order.
    var words: [PronunciationWordResult] = []
}

/// Individual word pronunciation assessment.
struct PronunciationWordResult: Identifiable {
    let id = UUID()
    let word: String
    let score: Double
}
