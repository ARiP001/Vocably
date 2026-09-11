//
//  SettingViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class SettingViewModel {
    var draftName = ""
    var draftInterest = "General"
    var draftDailyGoal = 3
    var originalName = ""
    var originalInterest = "General"
    var originalDailyGoal = 3
    var hasLoadedInitialValue = false
    var showSavedState = false
    var showResetAlert = false

    let interests = ["General", "Technology", "Business", "Marketing", "Finance", "Engineering", "Creative"]
    let step = 1
    let range = 1...50

    var hasChanges: Bool {
        draftName != originalName ||
        draftInterest != originalInterest ||
        draftDailyGoal != originalDailyGoal
    }

    func loadInitialValues(userName: String, selectedInterest: String, dailyGoal: Int) {
        guard !hasLoadedInitialValue else { return }
        draftName = userName
        draftInterest = selectedInterest
        draftDailyGoal = dailyGoal
        originalName = userName
        originalInterest = selectedInterest
        originalDailyGoal = dailyGoal
        hasLoadedInitialValue = true
    }

    func saveSettings(
        userName: inout String,
        selectedInterest: inout String,
        dailyGoal: inout Int,
        onDismiss: @escaping () -> Void
    ) {
        guard hasChanges else { return }

        userName = draftName
        selectedInterest = draftInterest
        dailyGoal = draftDailyGoal

        originalName = draftName
        originalInterest = draftInterest
        originalDailyGoal = draftDailyGoal

        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedState = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            onDismiss()
        }
    }

    func resetToDefault(
        userName: inout String,
        selectedInterest: inout String,
        dailyGoal: inout Int,
        hasCompletedOnboarding: inout Bool,
        progressStores: [LearningProgressStore],
        personalizationCaches: [PersonalizedVocabularyCache],
        modelContext: ModelContext
    ) {
        userName = "Himmel"
        selectedInterest = "General"
        dailyGoal = 3

        draftName = userName
        draftInterest = selectedInterest
        draftDailyGoal = dailyGoal
        originalName = userName
        originalInterest = selectedInterest
        originalDailyGoal = dailyGoal
        showSavedState = false

        for item in progressStores {
            modelContext.delete(item)
        }
        for item in personalizationCaches {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            // Keep reset flow running even if persistence save fails.
        }

        hasCompletedOnboarding = false
    }
}
