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
    var draftInterest = AppDefaults.defaultInterest
    var draftDailyGoal = AppDefaults.defaultDailyGoal
    var originalName = ""
    var originalInterest = AppDefaults.defaultInterest
    var originalDailyGoal = AppDefaults.defaultDailyGoal
    var showSavedState = false
    var showResetAlert = false

    var interests: [String] {
        AppDefaults.availableInterests
    }
    let step = 1
    let range = 1...50

    var hasChanges: Bool {
        draftName != originalName ||
        draftInterest != originalInterest ||
        draftDailyGoal != originalDailyGoal
    }

    func loadSettings() {
        let defaults = UserDefaults.standard
        let storedName = defaults.string(forKey: SettingsKey.userName) ?? AppDefaults.fallbackLearnerName
        let storedInterest = defaults.string(forKey: SettingsKey.selectedInterest) ?? AppDefaults.defaultInterest
        let storedGoal = defaults.integer(forKey: SettingsKey.dailyGoal)
        let effectiveGoal = storedGoal > 0 ? storedGoal : AppDefaults.defaultDailyGoal

        draftName = storedName
        draftInterest = storedInterest
        draftDailyGoal = effectiveGoal
        originalName = storedName
        originalInterest = storedInterest
        originalDailyGoal = effectiveGoal
    }

    func saveSettings(onDismiss: @escaping () -> Void) {
        guard hasChanges else { return }

        let sanitizedName = AppDefaults.sanitizedName(draftName)
        let defaults = UserDefaults.standard
        defaults.set(sanitizedName, forKey: SettingsKey.userName)
        defaults.set(draftInterest, forKey: SettingsKey.selectedInterest)
        defaults.set(draftDailyGoal, forKey: SettingsKey.dailyGoal)

        draftName = sanitizedName
        originalName = sanitizedName
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

    func resetToDefault(context: ModelContext) {
        let defaults = UserDefaults.standard
        defaults.set(AppDefaults.fallbackLearnerName, forKey: SettingsKey.userName)
        defaults.set(AppDefaults.defaultInterest, forKey: SettingsKey.selectedInterest)
        defaults.set(AppDefaults.defaultDailyGoal, forKey: SettingsKey.dailyGoal)
        defaults.set(false, forKey: SettingsKey.hasCompletedOnboarding)

        loadSettings()
        showSavedState = false

        // Clear SwiftData persistence records
        try? context.delete(model: LearningProgressStore.self)
        try? context.delete(model: PersonalizedVocabularyCache.self)
        try? context.save()
    }
}
