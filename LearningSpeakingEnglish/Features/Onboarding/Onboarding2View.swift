//
//  Untitled.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/04/26.
//

import SwiftUI

struct Onboarding2View: View {
    let enteredName: String
    let selectedInterest: String
    var onComplete: (String, Int, String) -> Void
    @State var numberVocab = 3
    
    var body: some View {
        NavigationStack {
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
                        if numberVocab > 0 {
                            numberVocab -= 1
                        }
                    } label: {
                        Text("-")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(Color.brandSecondary)
                    }
                    
                    VStack(spacing: Spacing.xs) {
                        Text("\(numberVocab)")
                            .font(.system(size: 70, weight: .medium))
                        Rectangle()
                            .fill(Color.brandPrimary.opacity(0.35))
                            .frame(width: 40, height: 2)
                    }
                    
                    Button {
                        numberVocab += 1
                    } label: {
                        Text("+")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(Color.brandSecondary)
                    }
                }
                .padding(.vertical, Spacing.xxl)
                Text("Tips : It's recommended to start low")
                    .font(.bodyRegular)
                    .foregroundStyle(.gray)
                
                Spacer()
                PrimaryButton(title: "Get started") {
                    onComplete(enteredName, max(1, numberVocab), selectedInterest)
                }
            }
            .padding()
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.bgPrimary)
        }
    }
}

#Preview {
    Onboarding2View(enteredName: "Himmel", selectedInterest: "General") { _, _, _ in
    }
}
