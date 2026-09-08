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
            VStack(spacing: 20) {
                ProgressView(value: 0.5)
                    .tint(Color.appPrimary)
                    .scaleEffect(x: 1, y: 2)
                
                Divider()
                Image("man-reading-book")
                    .resizable()
                    .frame(width: 220, height: 220)
                    .padding(.top, 20)
                Text("Can you tell us about yourself")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 5) {
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
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Color.appSecondary.opacity(0.85))
                        }
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.top, 10)
                
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
    Onboarding1View { _, _, _ in
    }
}
