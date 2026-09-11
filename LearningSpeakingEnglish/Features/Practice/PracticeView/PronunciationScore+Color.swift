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

extension PronunciationWordResult {
    var color: Color {
        switch score {
        case 80...:
            return .green
        case 60..<80:
            return .yellow
        default:
            return .red
        }
    }
}
