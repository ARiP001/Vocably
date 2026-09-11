//
//  PronunciationResult.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
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

/// Overall speech recognition transcript and score assessment.
struct PronunciationResult {
    var recognizedText: String = ""
    var score: PronunciationScore = .unrecognized
    /// Overall Azure HundredMark score (0...100).
    var percentage: Double?
    /// Scores returned for each recognized word, in spoken order.
    var words: [PronunciationWordResult] = []
}

/// Individual word pronunciation assessment and highlighting color.
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
