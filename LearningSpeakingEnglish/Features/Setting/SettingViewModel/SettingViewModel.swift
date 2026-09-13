//
//  SettingViewModel.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import SwiftUI
import Observation

/// ViewModel yang mengelola pengaturan profil pengguna, pemilihan minat, dan preferensi target harian.
@Observable
final class SettingsViewModel {
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

        applySettings(name: storedName, interest: storedInterest, dailyGoal: effectiveGoal)
    }

    func saveSettings(onDismiss: @escaping () -> Void) {
        guard hasChanges else { return }

        let sanitizedName = AppDefaults.sanitizedName(draftName)
        persistSettings(name: sanitizedName, interest: draftInterest, dailyGoal: draftDailyGoal)
        applySettings(name: sanitizedName, interest: draftInterest, dailyGoal: draftDailyGoal)
        triggerSavedFeedback(onDismiss: onDismiss)
    }

    private func applySettings(name: String, interest: String, dailyGoal: Int) {
        draftName = name
        draftInterest = interest
        draftDailyGoal = dailyGoal
        originalName = name
        originalInterest = interest
        originalDailyGoal = dailyGoal
    }

    private func persistSettings(name: String, interest: String, dailyGoal: Int) {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: SettingsKey.userName)
        defaults.set(interest, forKey: SettingsKey.selectedInterest)
        defaults.set(dailyGoal, forKey: SettingsKey.dailyGoal)
    }

    private func triggerSavedFeedback(onDismiss: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedState = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            onDismiss()
        }
    }

    func resetToDefault(onClearPersistence: (() -> Void)? = nil) {
        let defaults = UserDefaults.standard
        defaults.set(AppDefaults.fallbackLearnerName, forKey: SettingsKey.userName)
        defaults.set(AppDefaults.defaultInterest, forKey: SettingsKey.selectedInterest)
        defaults.set(AppDefaults.defaultDailyGoal, forKey: SettingsKey.dailyGoal)
        defaults.set(false, forKey: SettingsKey.hasCompletedOnboarding)

        loadSettings()
        showSavedState = false

        onClearPersistence?()
    }
}

/// Alias kompatibilitas ke belakang untuk SettingsViewModel.
typealias SettingViewModel = SettingsViewModel
