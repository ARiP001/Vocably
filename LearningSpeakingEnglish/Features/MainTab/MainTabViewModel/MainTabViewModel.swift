//
//  MainTabViewModel.swift
//  LearningSpeakingEnglish
//

import SwiftUI
import Observation

@Observable
final class MainTabViewModel {
    var session: LearningSession
    var hasRestoredProgress = false

    init(dailyGoal: Int, interest: String) {
        self.session = VocabularyDataService.createSession(dailyGoal: dailyGoal, interest: interest)
    }

    func updateDailyGoal(_ newGoal: Int) {
        session.dailyGoal = max(1, newGoal)
    }

    func updateInterest(_ newInterest: String) {
        session.selectedInterest = newInterest
    }
}
