//
//  Untitled.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/04/26.
//

import SwiftUI

/// Screen for selecting daily vocabulary learning goal during onboarding.
struct OnboardingGoalView: View {
    let viewModel: OnboardingViewModel
    var onComplete: (_ name: String, _ dailyGoal: Int, _ interest: String) -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView(value: 1)
                .tint(Color.brandPrimary)
                .scaleEffect(x: 1, y: 2)
            
            Divider()
            Text("How many Vocab you\nwant to learn per day ?")
                .font(.title2Regular)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xl)
            HStack(spacing: 60) {
                
                Button {
                    viewModel.decrementDailyGoal()
                } label: {
                    Text("-")
                        .font(.largeTitleBold)
                        .foregroundStyle(Color.brandSecondary)
                }
                
                VStack(spacing: Spacing.xs) {
                    Text("\(viewModel.dailyGoalCount)")
                        .font(.largeTitleBold)
                    Rectangle()
                        .fill(Color.brandPrimary.opacity(0.35))
                        .frame(width: 40, height: 2)
                }
                
                Button {
                    viewModel.incrementDailyGoal()
                } label: {
                    Text("+")
                        .font(.largeTitleBold)
                        .foregroundStyle(Color.brandSecondary)
                }
            }
            .padding(.vertical, Spacing.xxl)
            Text("Tips : It's recommended to start low")
                .font(.bodyRegular)
                .foregroundStyle(.gray)
            
            Spacer()
            PrimaryButton(title: "Get started") {
                viewModel.complete(onComplete: onComplete)
            }
        }
        .padding()
        .navigationTitle("Onboarding")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.bgPrimary)
    }
}

/// Backward compatibility alias for OnboardingGoalView.
typealias Onboarding2View = OnboardingGoalView

#Preview {
    NavigationStack {
        OnboardingGoalView(viewModel: OnboardingViewModel()) { _, _, _ in
        }
    }
}
