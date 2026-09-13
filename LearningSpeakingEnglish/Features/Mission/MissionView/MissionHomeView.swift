//
//  MissionHomeView.swift
//  LearningSpeakingEnglish
//

import SwiftUI
import SwiftData

struct MissionHomeView: View {
    let userName: String
    let selectedDomain: String
    @Binding var session: LearningSession
    @Environment(\.modelContext) private var modelContext
    @Query private var personalizationCaches: [PersonalizedVocabularyCache]
    @State private var viewModel = MissionHomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    greetingCard
                    if viewModel.hasCompletedDailyTarget(session: session) {
                        completionBanner
                    }
                    progressCard
                    missionCard
                }
                .padding()
            }
            .background(Color.bgPrimary)
            .navigationTitle("Mission")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedDomain) {
                if viewModel.recommendedVocabulary == nil {
                    viewModel.loadRecommendation(selectedDomain: selectedDomain, session: session)
                }
                let upcoming = viewModel.upcomingVocabulary(for: selectedDomain)
                await VocabularyPersonalizationService.prefetch(
                    words: upcoming,
                    domain: selectedDomain,
                    caches: personalizationCaches,
                    in: modelContext
                )
            }
            .onChange(of: selectedDomain) { _, _ in
                viewModel.resetForDomain(selectedDomain: selectedDomain, session: session)
            }
        }
    }

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.caption1Regular)
                .foregroundStyle(.secondary)

            Text(viewModel.displayName(for: userName))
                .font(.title3Bold)
                .foregroundStyle(.primary)

            Text("Ready for your mission today?")
                .font(.subheadRegular)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, -20)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Daily Progress")
                    .font(.subheadSemibold)
                Spacer()
                Text(session.progressText)
                    .font(.subheadSemibold)
                    .foregroundStyle(Color.brandPrimary)
            }

            RunnerProgressView(progress: session.progressValue)
                .frame(height: 15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            viewModel.hasCompletedDailyTarget(session: session)
            ? Color.brandPrimary.opacity(0.12)
            : Color.bgSecondary
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
    
    private var completionBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image.partyPopper
                .foregroundStyle(Color.brandSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Congratulations!")
                    .font(.subheadSemibold)
                Text("You hit your daily vocab target.")
                    .font(.caption1Regular)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Mission")
                .font(.headlineRegular)

            if let vocab = viewModel.recommendedVocabulary {
                HStack(alignment: .top, spacing: 12) {
                    Text(vocab.word)
                        .font(.title1Bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Skip") {
                        viewModel.skipCurrentWord(selectedDomain: selectedDomain, session: session)
                    }
                    .font(.caption1Semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                HStack {
                    ListenAudioButton(title: vocab.pronunciation?.ipa ?? "Listen") {
                        viewModel.speak(word: vocab.word)
                    }
                    
                    Spacer()
                }

                Text(vocab.allDefinitions.first?.description ?? "Vocabulary practice")
                    .font(.subheadRegular)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    CuratedMissionDetailView(
                        vocabulary: vocab,
                        selectedDomain: selectedDomain
                    ) {
                        viewModel.completeMission(
                            for: vocab,
                            selectedDomain: selectedDomain,
                            session: &session
                        )
                    }
                } label: {
                    Text("Start Mission")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.brandPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else {
                ContentUnavailableView("No Mission", systemImage: "book.closed")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

#Preview {
    MissionHomePreviewWrapper()
}

private struct MissionHomePreviewWrapper: View {
    @State private var session = VocabularyDataService.createSession(
        dailyGoal: AppDefaults.defaultDailyGoal,
        interest: AppDefaults.defaultInterest
    )

    var body: some View {
        MissionHomeView(
            userName: AppDefaults.fallbackLearnerName,
            selectedDomain: "Technology",
            session: $session
        )
    }
}
