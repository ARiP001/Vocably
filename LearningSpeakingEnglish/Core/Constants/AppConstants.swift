//
//  AppConstants.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// Nilai konfigurasi bawaan terpusat dan metadata domain untuk aplikasi.
enum AppDefaults {
    static let fallbackLearnerName = "Learner"
    static let defaultInterest = "General"
    static let defaultDailyGoal = 3
    static let minDailyGoal = 1
    static let maxDailyGoal = 20

    static let availableInterests: [String] = [
        "General",
        "Technology",
        "Business",
        "Marketing",
        "Finance",
        "Engineering",
        "Creative"
    ]

    /// Membersihkan spasi dan baris baru pada nama input pengguna, dengan fallback ke sebutan pembelajar default.
    static func sanitizedName(_ rawName: String) -> String {
        let cleaned = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? fallbackLearnerName : cleaned
    }
}

/// Kunci penyimpanan standar UserDefaults yang digunakan di seluruh aplikasi.
enum SettingsKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userName = "userName"
    static let selectedInterest = "selectedInterest"
    static let dailyGoal = "dailyGoal"
}
