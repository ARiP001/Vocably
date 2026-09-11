//
//  LearningSpeakingEnglishApp.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/04/26.
//

import SwiftUI
import SwiftData

@main
struct LearningSpeakingEnglishApp: App {
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKey.userName) private var userName = AppDefaults.fallbackLearnerName
    @AppStorage(SettingsKey.dailyGoal) private var dailyGoal = AppDefaults.defaultDailyGoal
    @AppStorage(SettingsKey.selectedInterest) private var selectedInterest = AppDefaults.defaultInterest
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView(
                        dailyGoal: dailyGoal,
                        interest: selectedInterest,
                        userName: userName
                    )
                } else {
                    Onboarding1View { name, selectedDailyGoal, interest in
                        userName = name
                        dailyGoal = selectedDailyGoal
                        selectedInterest = interest
                        hasCompletedOnboarding = true
                    }
                }
            }
            .tint(Color.brandPrimary)
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [LearningProgressStore.self, PersonalizedVocabularyCache.self])
    }
}
