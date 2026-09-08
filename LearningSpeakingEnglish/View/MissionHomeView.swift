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
                VStack(spacing: 16) {
                    greetingCard
                    if hasCompletedDailyTarget {
                        completionBanner
                    }
                    progressCard
                    missionCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Ready for your mission today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, -20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Progress")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(session.progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            RunnerProgressView(progress: session.progressValue)
                .frame(height: 15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            hasCompletedDailyTarget
            ? Color.appPrimary.opacity(0.12)
            : Color(.secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var completionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "party.popper.fill")
                .foregroundStyle(Color.appSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Congratulations!")
                    .font(.subheadline.weight(.bold))
                Text("You hit your daily vocab target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.appPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Mission")
                .font(.headline)

            if let vocab = recommendedVocabulary {
                HStack(alignment: .top, spacing: 12) {
                    Text(vocab.word)
                        .font(.title.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Skip") {
                        recommendNext(excluding: vocab.id)
                    }
                    .font(.caption.weight(.semibold))
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
                        HStack(spacing: 8) {
                            Text(vocab.pronunciation?.ipa ?? "Listen")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .foregroundStyle(Color.appSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appSecondary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }

                Text(vocab.allDefinitions.first?.description ?? "Vocabulary practice")
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
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else {
                ContentUnavailableView("No Mission", systemImage: "book.closed")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
