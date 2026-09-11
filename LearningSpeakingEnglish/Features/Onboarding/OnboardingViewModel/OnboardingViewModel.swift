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
    var name: String = ""
    var selectedInterest: String = AppDefaults.defaultInterest
    var numberVocab: Int = AppDefaults.defaultDailyGoal

    var interests: [String] {
        AppDefaults.availableInterests
    }

    let minVocab: Int = AppDefaults.minDailyGoal
    let maxVocab: Int = AppDefaults.maxDailyGoal

    func incrementVocab() {
        numberVocab = min(maxVocab, numberVocab + 1)
    }

    func decrementVocab() {
        numberVocab = max(minVocab, numberVocab - 1)
    }

    func complete(onComplete: (String, Int, String) -> Void) {
        let finalName = AppDefaults.sanitizedName(name)
        onComplete(finalName, max(minVocab, numberVocab), selectedInterest)
    }
}
