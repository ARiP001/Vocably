//
//  PronunciationScore+Color.swift
//  LearningSpeakingEnglish
//

import SwiftUI

extension PronunciationScore {
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

extension WordAccuracy {
    var color: Color {
        switch self {
        case .accurate:
            return .green
        case .acceptable:
            return .yellow
        case .poor:
            return .red
        case .unassessed:
            return .primary
        }
    }
}

extension PronunciationWordResult {
    var accuracy: WordAccuracy {
        WordAccuracy(score: score)
    }

    var color: Color {
        accuracy.color
    }
}
