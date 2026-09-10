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
    @State private var skippedWordIDs: Set<String> = []
    
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
                skippedWordIDs.removeAll()
                recommendedVocabulary = nil
                loadRecommendation()
            }
        }
    }

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.caption1Regular)
                .foregroundStyle(.secondary)

            Text(displayName)
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

            if let vocab = recommendedVocabulary {
                HStack(alignment: .top, spacing: 12) {
                    Text(vocab.word)
                        .font(.title1Bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Skip") {
                        skippedWordIDs.insert(vocab.id.lowercased())
                        recommendNext(excluding: vocab.id)
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
                        SpeechHelper.speak(vocab.word, languageCode: "en-US")
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
        let learned = session.learnedWordNames

        // 1. First priority: Unlearned word that has not been skipped in this session
        if let next = ranked.first(where: { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            guard !skippedWordIDs.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }) {
            recommendedVocabulary = next.vocabulary
            return
        }

        // 2. Second priority: If all unlearned words in domain were skipped, reset skipped list and pick next
        if let next = ranked.first(where: { item in
            let key = item.vocabulary.word.lowercased()
            guard !learned.contains(key) else { return false }
            if let wordID, key == wordID.lowercased() { return false }
            return true
        }) {
            skippedWordIDs.removeAll()
            if let wordID { skippedWordIDs.insert(wordID.lowercased()) }
            recommendedVocabulary = next.vocabulary
            return
        }

        // 3. Fallback: If all words in domain are learned, show next available word excluding current
        recommendedVocabulary = ranked.first(where: {
            $0.vocabulary.word.caseInsensitiveCompare(wordID ?? "") != .orderedSame
        })?.vocabulary
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
