//
//  ContentView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/04/26.
//

import SwiftUI

/// Screen for setting up user profile and interest area during onboarding.
struct OnboardingProfileView: View {
    var onComplete: (_ name: String, _ dailyGoal: Int, _ interest: String) -> Void
    @State private var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                ProgressView(value: 0.5)
                    .tint(Color.brandPrimary)
                    .scaleEffect(x: 1, y: 2)
                
                Divider()
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
                    
                    TextField("", text: $viewModel.name)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Interest")
                        .foregroundStyle(.gray)
                    
                    Menu {
                        ForEach(viewModel.interests, id: \.self) { i in
                            Button(i) {
                                viewModel.selectedInterest = i
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedInterest)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image.chevronDown
                                .foregroundStyle(Color.brandSecondary.opacity(0.85))
                        }
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.top, Spacing.sm)
                
                Spacer()
                NavigationLink {
                    OnboardingGoalView(
                        viewModel: viewModel,
                        onComplete: onComplete
                    )
                } label: {
                    Text("Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.bgPrimary)
        }
    }
}

/// Backward compatibility alias for OnboardingProfileView.
typealias Onboarding1View = OnboardingProfileView

#Preview {
    OnboardingProfileView { _, _, _ in
    }
}
