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
                    HStack(spacing: Spacing.sm) {
                        Button {
                            onRetry()
                            isPresented = false
                        } label: {
                            Text("Retry")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(Color.bgSecondary)
                                .clipShape(Capsule())
                                .foregroundStyle(Color.brandPrimary)
                        }
                        
                        PrimaryButton(title: "Next") {
                            onNext()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isPresented = false
                            }
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
