//
//  EvaluatedPromptView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

/// Renders evaluated words with their respective accuracy feedback colors.
struct EvaluatedPromptText: View {
    let evaluatedWords: [EvaluatedWord]

    var body: some View {
        evaluatedWords.enumerated().reduce(Text("")) { output, element in
            let (index, item) = element
            let color = color(for: item.accuracy)
            let styledWord = Text(item.word).foregroundStyle(color)
            if index == 0 {
                return Text("\(styledWord)")
            }
            return Text("\(output) \(styledWord)")
        }
    }

    private func color(for accuracy: WordAccuracy) -> Color {
        switch accuracy {
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
