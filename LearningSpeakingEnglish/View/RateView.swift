//
//  Rate.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 19/04/26.
//

import SwiftUI

struct ResultAlertView: View {
    @Binding var isPresented: Bool
    var rating: Int
    var onRetry: () -> Void
    var onNext: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                VStack(spacing: 20) {
                    Text("Rate your learn result")
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < rating ? "star.fill" : "star")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.appSecondary)
                        }
                    }
                    HStack(spacing: 12) {
                        Button {
                            onRetry()
                            isPresented = false
                        } label: {
                            Text("Retry")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.appPrimary)
                        }
                        
                        Button {
                            onNext()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isPresented = false
                            }
                        } label: {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.easeInOut, value: isPresented)
        }
    }
}
