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
    @State private var vocabulary: [RecommendedVocabulary] = []
    @State private var recommendedVocabulary: RecommendedVocabulary?
    
    private var hasCompletedDailyTarget: Bool {
        session.dailyTargetCount > 0 && session.completedToday >= session.dailyTargetCount
    }

    var body: some View {
        NavigationStack {

            ScrollView {
                VStack(spacing: Spacing.md) {
                    greetingCard
                    if hasCompletedDailyTarget {
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
                if recommendedVocabulary == nil {
                    loadRecommendation()
                }
                await prefetchUpcomingVocabulary()
            }
            .onChange(of: selectedDomain) { _, _ in
                recommendedVocabulary = nil
                loadRecommendation()
            }
        }
    }

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(AppFont.caption1Regular)
                .foregroundStyle(.secondary)

            Text(displayName)
                .font(AppFont.title3Bold)
                .foregroundStyle(.primary)

            Text("Ready for your mission today?")
                .font(AppFont.subheadRegular)
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
                    .font(AppFont.subheadSemibold)
                Spacer()
                Text(session.progressText)
                    .font(AppFont.subheadSemibold)
                    .foregroundStyle(Color.brandPrimary)
            }

            RunnerProgressView(progress: session.progressValue)
                .frame(height: 15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            hasCompletedDailyTarget
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
                    .font(AppFont.subheadSemibold)
                Text("You hit your daily vocab target.")
                    .font(AppFont.caption1Regular)
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
                .font(AppFont.headlineRegular)

            if let vocab = recommendedVocabulary {
                HStack(alignment: .top, spacing: 12) {
                    Text(vocab.word)
                        .font(AppFont.title1Bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Skip") {
                        recommendNext(excluding: vocab.id)
                    }
                    .font(AppFont.caption1Semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                HStack {
                    Button {
                        SpeechHelper.speak(vocab.word, languageCode: "en-US")
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(vocab.pronunciation?.ipa ?? "Listen")
                                .font(AppFont.subheadMedium)
                            Image.speaker
                        }
                        .foregroundStyle(Color.brandSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.brandSecondary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }

                Text(vocab.allDefinitions.first?.description ?? "Vocabulary practice")
                    .font(AppFont.subheadRegular)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    CuratedMissionDetailView(
                        vocabulary: vocab,
                        selectedDomain: selectedDomain
                    ) {
                        session.finishLearning(named: vocab.word)
                        recommendNext(excluding: vocab.id)
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

    private var displayName: String {
        let cleanedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedName.isEmpty ? "Learner" : cleanedName
    }

    private func loadRecommendation() {
        if vocabulary.isEmpty {
            vocabulary = VocabularyData.load()
        }
        recommendNext(excluding: nil)
    }

    private func recommendNext(excluding wordID: String?) {
        let ranked = RecommendationEngine.rank(vocabulary: vocabulary, selectedDomain: selectedDomain)
        recommendedVocabulary = ranked.first(where: { $0.vocabulary.id != wordID })?.vocabulary
    }

    private func prefetchUpcomingVocabulary() async {
        guard VocabularyPersonalizationHelper.isAvailable else { return }

        let ranked = RecommendationEngine.rank(
            vocabulary: vocabulary,
            selectedDomain: selectedDomain
        )
        let upcoming = Array(ranked.prefix(10))
        let cachedKeys = Set(personalizationCaches.map(\.cacheKey))
        let cachedCount = upcoming.filter {
            cachedKeys.contains(PersonalizationCacheHelper.key(for: $0.vocabulary, domain: selectedDomain))
        }.count

        guard cachedCount < 5 else { return }

        var preparedKeys = cachedKeys
        for item in upcoming {
            if Task.isCancelled { return }

            let key = PersonalizationCacheHelper.key(for: item.vocabulary, domain: selectedDomain)
            guard !preparedKeys.contains(key) else { continue }

            let result = await VocabularyPersonalizationHelper.prepareDeduplicated(
                vocabulary: item.vocabulary,
                domain: selectedDomain
            )
            PersonalizationCacheHelper.save(
                result: result,
                vocabulary: item.vocabulary,
                domain: selectedDomain,
                in: modelContext
            )
            if result.status == .ready {
                preparedKeys.insert(key)
            }
        }
    }
}

#Preview {
    MissionHomePreviewWrapper()
}

private struct MissionHomePreviewWrapper: View {
    @State private var session = LearningSession.placeholder(dailyGoal: 3, interest: "General")

    var body: some View {
        MissionHomeView(userName: "Himmel", selectedDomain: "Technology", session: $session)
    }
}
