//
//  LearningStepProgressView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

struct LearningStepProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    private var safeTotal: Int {
        max(1, totalSteps)
    }

    private var progressValue: Double {
        Double(min(max(currentStep, 0), safeTotal)) / Double(safeTotal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Learning Progress")
                    .font(AppFont.subheadSemibold)
                Spacer()
                Text("Step \(currentStep)/\(safeTotal)")
                    .font(AppFont.caption1Medium)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressValue)
                .tint(Color.brandPrimary)
                .scaleEffect(x: 1, y: 1.4)
                .animation(.easeInOut(duration: 0.35), value: progressValue)
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
