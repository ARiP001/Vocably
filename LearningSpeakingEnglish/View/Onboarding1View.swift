//
//  ContentView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/04/26.
//

import SwiftUI

struct Onboarding1View: View {
    var onComplete: (String, Int, String) -> Void
    @State private var name = "Himmel"
    @State private var selectedInterest = "General"
    let interests = ["General", "Technology", "Business", "Marketing", "Finance", "Engineering", "Creative"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                ProgressView(value: 0.5)
                    .tint(Color.brandPrimary)
                    .scaleEffect(x: 1, y: 2)
                
                Divider()
                Image("man-reading-book")
                    .resizable()
                    .frame(width: 220, height: 220)
                    .padding(.top, Spacing.lg)
                Text("Can you tell us about yourself")
                    .font(AppFont.title2Regular)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Name (optional)")
                        .foregroundStyle(.gray)
                    
                    TextField("", text: $name)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Interest")
                        .foregroundStyle(.gray)
                    
                    Menu {
                        ForEach(interests, id: \.self) { i in
                            Button(i) {
                                selectedInterest = i
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedInterest)
                                .foregroundStyle(
                                    Color(UIColor { trait in
                                        trait.userInterfaceStyle == .dark ? .white : .black
                                    })
                                )
                            Spacer()
                            Image.chevronDown
                                .foregroundStyle(Color.brandSecondary.opacity(0.85))
                        }
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.top, Spacing.sm)
                
                Spacer()
                NavigationLink {
                    Onboarding2View(
                        enteredName: name,
                        selectedInterest: selectedInterest,
                        onComplete: onComplete
                    )
                } label: {
                    Text("Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
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
    Onboarding1View { _, _, _ in
    }
}
