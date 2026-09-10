//
//  RecordingSheetView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

struct RecordingSheetView: View {
    @Binding var showRecordingSheet: Bool
    let recordingTitle: String
    let recordingHint: String
    let recordingSeconds: Int
    let onStopRecording: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Capsule()
                .fill(.gray.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, Spacing.sm)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(recordingTitle)
                    .font(AppFont.title2Bold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recordingHint)
                    .font(AppFont.subheadRegular)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, Spacing.xs)

            VStack(spacing: Spacing.sm) {
                Text(formattedSeconds(recordingSeconds))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.black)

                HStack(spacing: 7) {
                    ForEach(0..<7) { i in
                        let base = (i % 2 == 0) ? 26 : 40
                        let extra = i * 3
                        let height = CGFloat(base + extra)

                        Capsule()
                            .fill(Color.brandPrimary.opacity(0.35 + Double(i) * 0.07))
                            .frame(width: 7, height: height)
                    }
                }
            }

            Spacer(minLength: 10)

            Button {
                onStopRecording()
            } label: {
                Image.stop
                    .font(AppFont.title2Bold)
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.brandSecondary)
                    .clipShape(Circle())
            }

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    Capsule()
                        .fill(Color.gray.opacity(0.2 + Double(i) * 0.08))
                        .frame(width: 10, height: 3)
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 40)
    }

    private func formattedSeconds(_ total: Int) -> String {
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
