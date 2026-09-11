//
//  SettingViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import SwiftData
import Observation

enum SettingsKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userName = "userName"
    static let selectedInterest = "selectedInterest"
    static let dailyGoal = "dailyGoal"
}

@Observable
final class SettingViewModel {
    var draftName = ""
    var draftInterest = "General"
    var draftDailyGoal = 3
    var originalName = ""
    var originalInterest = "General"
    var originalDailyGoal = 3
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

    func loadSettings() {
        let defaults = UserDefaults.standard
        let storedName = defaults.string(forKey: SettingsKey.userName) ?? "Himmel"
        let storedInterest = defaults.string(forKey: SettingsKey.selectedInterest) ?? "General"
        let storedGoal = defaults.integer(forKey: SettingsKey.dailyGoal)
        let effectiveGoal = storedGoal > 0 ? storedGoal : 3

        draftName = storedName
        draftInterest = storedInterest
        draftDailyGoal = effectiveGoal
        originalName = storedName
        originalInterest = storedInterest
        originalDailyGoal = effectiveGoal
    }

    func saveSettings(onDismiss: @escaping () -> Void) {
        guard hasChanges else { return }

        let defaults = UserDefaults.standard
        defaults.set(draftName, forKey: SettingsKey.userName)
        defaults.set(draftInterest, forKey: SettingsKey.selectedInterest)
        defaults.set(draftDailyGoal, forKey: SettingsKey.dailyGoal)

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

    func resetToDefault(context: ModelContext) {
        let defaults = UserDefaults.standard
        defaults.set("Himmel", forKey: SettingsKey.userName)
        defaults.set("General", forKey: SettingsKey.selectedInterest)
        defaults.set(3, forKey: SettingsKey.dailyGoal)
        defaults.set(false, forKey: SettingsKey.hasCompletedOnboarding)

        loadSettings()
        showSavedState = false

        // Clear SwiftData persistence records
        try? context.delete(model: LearningProgressStore.self)
        try? context.delete(model: PersonalizedVocabularyCache.self)
        try? context.save()
    }
}
