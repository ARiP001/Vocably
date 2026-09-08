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
        VStack(spacing: 20) {
            Capsule()
                .fill(.gray.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(recordingTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recordingHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 4)

            VStack(spacing: 10) {
                Text(formattedSeconds(recordingSeconds))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.black)

                HStack(spacing: 7) {
                    ForEach(0..<7) { i in
                        let base = (i % 2 == 0) ? 26 : 40
                        let extra = i * 3
                        let height = CGFloat(base + extra)

                        Capsule()
                            .fill(Color.appPrimary.opacity(0.35 + Double(i) * 0.07))
                            .frame(width: 7, height: height)
                    }
                }
            }

            Spacer(minLength: 10)

            Button {
                onStopRecording()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.appSecondary)
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
