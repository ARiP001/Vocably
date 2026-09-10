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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = "Himmel"
    @AppStorage("dailyGoal") private var dailyGoal = 3
    @AppStorage("selectedInterest") private var selectedInterest = "General"
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                } else {
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
            }
            .tint(Color.appPrimary)
            .preferredColorScheme(.light)
            .onAppear {
                guard showSplash else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(for: [LearningProgressStore.self, PersonalizedVocabularyCache.self])
    }
}
