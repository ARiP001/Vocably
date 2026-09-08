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
            VStack(spacing: 20) {
//                Text("Onboarding")
//                    .font(.title2)
//                    .fontWeight(.medium)

                ProgressView(value: 1)
                    .tint(Color.appPrimary)
                    .scaleEffect(x: 1, y: 2)
    //                .padding(.vertical, 10)
                
                Divider()
                Text("How many Vocab you\nwant to learn per day ?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)
                HStack(spacing: 60) {
                    
                    Button {
                        if numberVocab > 0 {
                            numberVocab -= 1
                        }
                    } label: {
                        Text("-")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(Color.appSecondary)
                    }
                    
                    VStack(spacing: 5) {
                        Text("\(numberVocab)")
                            .font(.system(size: 70, weight: .medium))
                        Rectangle()
                            .fill(Color.appPrimary.opacity(0.35))
                            .frame(width: 40, height: 2)
                    }
                    
                    Button {
                        numberVocab += 1
                    } label: {
                        Text("+")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                .padding(.vertical, 40)
                Text("Tips : It's recommended to start low")
                    .font(.body)
                    .foregroundStyle(.gray)
                
                Spacer()
                Button {
                    onComplete(enteredName, max(1, numberVocab), selectedInterest)
                } label: {
                    Text("Get started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    Onboarding2View(enteredName: "Himmel", selectedInterest: "General") { _, _, _ in
    }
}
