//
//  EvaluatedPromptView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

/// Menampilkan teks kata-kata yang telah dievaluasi dengan warna umpan balik akurasi masing-masing.
struct EvaluatedPromptText: View {
    let evaluatedWords: [EvaluatedWord]

    var body: some View {
        evaluatedWords.enumerated().reduce(Text("")) { output, element in
            let (index, item) = element
            let styledWord = Text(item.word).foregroundStyle(item.accuracy.color)
            if index == 0 {
                return Text("\(styledWord)")
            }
            return Text("\(output) \(styledWord)")
        }
    }
}
