//
//  SettingView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 15/04/26.
//

import SwiftUI
import SwiftData

/// Screen for editing user profile, domain of interest, and daily vocabulary goal.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image("man-reading-book")
                    .resizable()
                    .frame(width: 220, height: 220)
                    .padding(.top, Spacing.lg)
                Text("Can you tell us about yourself")
                    .font(.title2Regular)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Name (optional)")
                        .foregroundStyle(.gray)
                    
                    TextField("", text: $viewModel.draftName)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Interest")
                        .foregroundStyle(.gray)
                    
                    Menu {
                        ForEach(viewModel.interests, id: \.self) { i in
                            Button(i) {
                                viewModel.draftInterest = i
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.draftInterest)
                                .foregroundStyle(.primary)
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
                        
                    Stepper(value: $viewModel.draftDailyGoal, in: viewModel.range, step: viewModel.step) {
                        TextField("Target", value: $viewModel.draftDailyGoal, format: .number)
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
                    viewModel.saveSettings {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if viewModel.showSavedState {
                            Image.checkmark
                        }
                        Text(viewModel.showSavedState ? "Saved" : "Confirm")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(viewModel.hasChanges ? Color.brandPrimary : Color.gray.opacity(0.35))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(viewModel.showSavedState || !viewModel.hasChanges)
            }
            .padding()
            .navigationTitle("Edit Setting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        viewModel.showResetAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .background(Color.bgPrimary)
            .onAppear {
                viewModel.loadSettings()
            }
            .alert("Reset all settings?", isPresented: $viewModel.showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetToDefault {
                        try? modelContext.delete(model: LearningProgressStore.self)
                        try? modelContext.delete(model: PersonalizedVocabularyCache.self)
                        try? modelContext.save()
                    }
                }
            } message: {
                Text("This will reset your profile, daily goal, and learning progress.")
            }
        }
    }
}

/// Backward compatibility alias for SettingsView.
typealias SettingView = SettingsView

#Preview {
    SettingsView()
}
