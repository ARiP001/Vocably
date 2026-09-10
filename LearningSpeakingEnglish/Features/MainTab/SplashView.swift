//
//  SplashView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.14), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .shadow(color: .black.opacity(0.08), radius: Radius.md, y: 8)
                    .scaleEffect(animate ? 1 : 0.9)
                    .opacity(animate ? 1 : 0.7)

                Text("Vocab.ly")
                    .font(.title3Bold)
                    .opacity(animate ? 1 : 0.75)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}

#Preview {
    SplashView()
}
