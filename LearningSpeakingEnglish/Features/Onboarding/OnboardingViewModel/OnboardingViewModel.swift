//
//  OnboardingViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    var name: String = "Himmel"
    var selectedInterest: String = "General"
    var numberVocab: Int = 3

    let interests: [String] = [
        "General",
        "Technology",
        "Business",
        "Marketing",
        "Finance",
        "Engineering",
        "Creative"
    ]

    let minVocab: Int = 1
    let maxVocab: Int = 20

    func incrementVocab() {
        if numberVocab < maxVocab {
            numberVocab += 1
        }
    }

    func decrementVocab() {
        if numberVocab > minVocab {
            numberVocab -= 1
        }
    }

    func complete(onComplete: (String, Int, String) -> Void) {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanedName.isEmpty ? "Learner" : cleanedName
        onComplete(finalName, max(minVocab, numberVocab), selectedInterest)
    }
}
