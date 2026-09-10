//
//  PrimaryButton.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: Image? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    icon
                }
                Text(title)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isEnabled ? Color.brandPrimary : Color.gray.opacity(0.35))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Speak Now") {}
        PrimaryButton(title: "Continue", icon: Image.play) {}
        PrimaryButton(title: "Disabled", isEnabled: false) {}
    }
    .padding()
}
