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
                VStack(spacing: Spacing.lg) {
                    Text("Rate your learn result")
                        .font(.title3Bold)
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<5) { i in
                            (i < rating ? Image.starFill : Image.star)
                                .font(.system(size: 30))
                                .foregroundStyle(Color.brandSecondary)
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
                                .foregroundStyle(Color.brandPrimary)
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
                                .background(Color.brandPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .padding(.horizontal, 40)
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.easeInOut, value: isPresented)
        }
    }
}
