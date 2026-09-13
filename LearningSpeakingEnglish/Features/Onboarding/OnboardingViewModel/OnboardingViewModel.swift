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
    var dailyGoalCount: Int = AppDefaults.defaultDailyGoal

    var interests: [String] {
        AppDefaults.availableInterests
    }

    let minimumDailyGoal: Int = AppDefaults.minDailyGoal
    let maximumDailyGoal: Int = AppDefaults.maxDailyGoal

    func incrementDailyGoal() {
        dailyGoalCount = min(maximumDailyGoal, dailyGoalCount + 1)
    }

    func decrementDailyGoal() {
        dailyGoalCount = max(minimumDailyGoal, dailyGoalCount - 1)
    }

    func complete(onComplete: (_ name: String, _ dailyGoal: Int, _ interest: String) -> Void) {
        let finalName = AppDefaults.sanitizedName(name)
        onComplete(finalName, max(minimumDailyGoal, dailyGoalCount), selectedInterest)
    }
}
