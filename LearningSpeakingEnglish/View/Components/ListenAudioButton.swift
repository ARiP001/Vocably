//
//  ListenAudioButton.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

struct ListenAudioButton: View {
    var title: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image.speaker
                if let title, !title.isEmpty {
                    Text(title)
                }
            }
            .font(.subheadMedium)
            .foregroundStyle(Color.brandSecondary)
            .padding(.horizontal, title == nil ? 10 : 12)
            .padding(.vertical, 8)
            .background(Color.brandSecondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        ListenAudioButton(title: "Listen") {}
        ListenAudioButton(title: "/həˈloʊ/") {}
        ListenAudioButton {}
    }
    .padding()
}
