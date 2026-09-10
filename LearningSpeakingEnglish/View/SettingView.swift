//
//  SettingView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 15/04/26.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var progressStores: [LearningProgressStore]
    @Query private var personalizationCaches: [PersonalizedVocabularyCache]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = "Himmel"
    @AppStorage("selectedInterest") private var selectedInterest = "General"
    @AppStorage("dailyGoal") private var value = 3
    @State private var draftName = ""
    @State private var draftInterest = "General"
    @State private var draftDailyGoal = 3
    @State private var originalName = ""
    @State private var originalInterest = "General"
    @State private var originalDailyGoal = 3
    @State private var hasLoadedInitialValue = false
    @State private var showSavedState = false
    @State private var showResetAlert = false
    let interests = ["General", "Technology", "Business", "Marketing", "Finance", "Engineering", "Creative"]
    let step = 1
    let range = 1...50

    private var hasChanges: Bool {
        draftName != originalName ||
        draftInterest != originalInterest ||
        draftDailyGoal != originalDailyGoal
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image("man-reading-book")
                    .resizable()
                    .frame(width: 220, height: 220)
                    .padding(.top, Spacing.lg)
                Text("Can you tell us about yourself")
                    .font(AppFont.title2Regular)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Name (optional)")
                        .foregroundStyle(.gray)
                    
                    TextField("", text: $draftName)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Interest")
                        .foregroundStyle(.gray)
                    
                    Menu {
                        ForEach(interests, id: \.self) { i in
                            Button(i) {
                                draftInterest = i
                            }
                        }
                    } label: {
                        HStack {
                            Text(draftInterest)
                                .foregroundStyle(.black)
                            Spacer()
                            Image.chevronDown
                                .foregroundStyle(Color.brandSecondary.opacity(0.85))
                        }
                    }

                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Vocab per Day")
                            .foregroundStyle(.gray)
                        
                    Stepper(value: $draftDailyGoal, in: range, step: step) {
                        TextField("Target", value: $draftDailyGoal, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                        }
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.top, Spacing.sm)
                
                Spacer()
                Button {
                    saveAndClose()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if showSavedState {
                            Image.checkmark
                        }
                        Text(showSavedState ? "Saved" : "Confirm")
                    }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(hasChanges ? Color.brandPrimary : Color.gray.opacity(0.35))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(showSavedState || !hasChanges)
            }
            .padding()
            .navigationTitle("Edit Setting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        showResetAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .background(Color.bgPrimary)
            .onAppear {
                guard !hasLoadedInitialValue else { return }
                draftName = userName
                draftInterest = selectedInterest
                draftDailyGoal = value
                originalName = userName
                originalInterest = selectedInterest
                originalDailyGoal = value
                hasLoadedInitialValue = true
            }
            .alert("Reset all settings?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetToDefaultAndReturnOnboarding()
                }
            } message: {
                Text("This will reset your profile, daily goal, and learning progress.")
            }
        }
    }

    private func saveAndClose() {
        guard hasChanges else { return }

        userName = draftName
        selectedInterest = draftInterest
        value = draftDailyGoal

        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedState = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }

    private func resetToDefaultAndReturnOnboarding() {
        userName = "Himmel"
        selectedInterest = "General"
        value = 3

        draftName = userName
        draftInterest = selectedInterest
        draftDailyGoal = value
        originalName = userName
        originalInterest = selectedInterest
        originalDailyGoal = value
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


#Preview {
    SettingView()
}
