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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Learning Progress")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Step \(currentStep)/\(safeTotal)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressValue)
                .tint(Color.appPrimary)
                .scaleEffect(x: 1, y: 1.4)
                .animation(.easeInOut(duration: 0.35), value: progressValue)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
