//
//  RunnerProgressView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//

import SwiftUI

struct RunnerProgressView: View {
    var progress: CGFloat

    private var normalizedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 6)

                Capsule()
                    .fill(Color.brandPrimary)
                    .frame(width: width * normalizedProgress, height: 6)

                Image.run
                    .font(.caption1Bold)
                    .offset(x: max(0, width * normalizedProgress - 9))

                HStack {
                    Spacer()
                    Image.flag
                        .font(.caption1Bold)
                        .offset(x: 12)
                }
            }
        }
        .frame(height: 15)
    }
}

#Preview {
    RunnerProgressView(progress: 0.6)
        .padding()
}
