//
//  CuratedMissionDetailView.swift
//  LearningSpeakingEnglish
//

import SwiftUI
import SwiftData

/// Three-card, personalized learning view used by the JSON/Foundation Model POC.
struct CuratedMissionDetailView: View {
    let vocabulary: RecommendedVocabulary
    let selectedDomain: String
    let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var personalizationCaches: [PersonalizedVocabularyCache]
    @State private var content: PersonalizedVocabularyContent
    @State private var showFullDetails = false
    @State private var showSpeakingPractice = false
    @State private var personalizationStatus: PersonalizationStatus = .loading
    @State private var showPersonalizationAlert = false

    init(
        vocabulary: RecommendedVocabulary,
        selectedDomain: String,
        onFinished: @escaping () -> Void
    ) {
        self.vocabulary = vocabulary
        self.selectedDomain = selectedDomain
        self.onFinished = onFinished
        _content = State(initialValue: .fallback(for: vocabulary))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                vocabularyCard

                if personalizationStatus == .loading {
                    personalizationLoadingCard
                }

                ForEach(Array(content.definitions.enumerated()), id: \.offset) { index, definition in
                    definitionCard(definition, index: index)
                }

                Button("See More") {
                    showFullDetails = true
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(Color.appPrimary)
                .clipShape(Capsule())

                Button {
                    showSpeakingPractice = true
                } label: {
                    Text("Speak Now")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mission Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFullDetails) {
            FullVocabularyDetailView(vocabulary: vocabulary)
        }
        .navigationDestination(isPresented: $showSpeakingPractice) {
            PersonalizedSpeakingPracticeView(
                word: vocabulary.word,
                sentences: practiceSentences,
                onFinished: onFinished
            )
        }
        .alert("Personalized content unavailable", isPresented: $showPersonalizationAlert) {
            Button("Continue with dictionary content", role: .cancel) {}
        } message: {
            Text("Vocab.ly could not prepare personalized examples or Indonesian translations right now. You can continue with the original vocabulary content.")
        }
        .task(id: "\(vocabulary.id)-\(selectedDomain)") {
            personalizationStatus = .loading
            let cacheKey = PersonalizationCacheHelper.key(for: vocabulary, domain: selectedDomain)
            if let cache = personalizationCaches.first(where: { $0.cacheKey == cacheKey }),
               let cachedContent = PersonalizationCacheHelper.content(from: cache, vocabulary: vocabulary) {
                content = cachedContent
                personalizationStatus = .ready
                return
            }

            let result = await VocabularyPersonalizationHelper.prepareDeduplicated(
                vocabulary: vocabulary,
                domain: selectedDomain
            )
            content = result.content
            personalizationStatus = result.status
            PersonalizationCacheHelper.save(
                result: result,
                vocabulary: vocabulary,
                domain: selectedDomain,
                in: modelContext
            )
            if result.status == .unavailable || result.status == .failed {
                showPersonalizationAlert = true
            }
        }
    }

    private var personalizationLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.appPrimary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Preparing your lesson")
                    .font(.subheadline.weight(.semibold))
                Text("Selecting useful meanings and creating practice content…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var practiceSentences: [String] {
        let generated = content.generatedExamples.compactMap(\.first)
        let original = content.definitions.compactMap { $0.examples?.first }
        return Array((generated + original).prefix(2))
    }

    private var vocabularyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(vocabulary.word)
                        .font(.largeTitle.weight(.bold))
                    Text(content.translation?.word ?? "")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let ipa = vocabulary.pronunciation?.ipa {
                    Button {
                        SpeechHelper.speak(vocabulary.word)
                    } label: {
                        Label(ipa, systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appSecondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color.appSecondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 7) {
                Text(vocabulary.partOfSpeech)
                if let translation = content.translation?.partOfSpeech, !translation.isEmpty {
                    Text("•")
                    Text(translation)
                }
                Text("•")
                Text(vocabulary.cefrLevel)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func definitionCard(_ definition: RecommendedDefinition, index: Int) -> some View {
        let examples = content.generatedExamples.indices.contains(index) ? content.generatedExamples[index] : []
        let translations = content.translation?.examples.indices.contains(index) == true
            ? content.translation?.examples[index] ?? []
            : []
        let definitionTranslation = content.translation?.definitions.indices.contains(index) == true
            ? content.translation?.definitions[index]
            : nil

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Meaning \(index + 1)")
                    .font(.headline)
                Spacer()
                if let cefr = definition.cefr {
                    Text(cefr)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if let label = definition.label {
                Text(label)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            if let description = definition.description {
                Text(description)
                    .font(.body)
            }

            if let definitionTranslation, !definitionTranslation.isEmpty {
                Text(definitionTranslation)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if !examples.isEmpty {
                Divider()
                Text("Practice in \(selectedDomain)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appSecondary)

                ForEach(Array(examples.enumerated()), id: \.offset) { exampleIndex, example in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Button {
                                SpeechHelper.speak(example)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(Color.appSecondary)
                            }
                            .buttonStyle(.plain)
                            Text(example)
                        }
                        if translations.indices.contains(exampleIndex), !translations[exampleIndex].isEmpty {
                            Text(translations[exampleIndex])
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 27)
                        }
                    }
                    .padding(12)
                    .background(Color.appSecondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

/// Full, uncurated dictionary reference exposed from the mission's See More action.
struct FullVocabularyDetailView: View {
    let vocabulary: RecommendedVocabulary

    var body: some View {
        List {
            Section {
                if let ipa = vocabulary.pronunciation?.ipa {
                    Label(ipa, systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(Color.appSecondary)
                }
                Text("\(vocabulary.partOfSpeech) • \(vocabulary.cefrLevel)")
                    .foregroundStyle(.secondary)
                if vocabulary.domain.isEmpty {
                    Text("General vocabulary")
                        .foregroundStyle(.secondary)
                } else {
                    Text(vocabulary.domain.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(vocabulary.allDefinitions.enumerated()), id: \.offset) { index, definition in
                Section("Meaning \(index + 1)") {
                    if let label = definition.label {
                        Text(label)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    if let description = definition.description {
                        Text(description)
                    }
                    if let examples = definition.examples, !examples.isEmpty {
                        ForEach(examples, id: \.self) { example in
                            Text(example)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(vocabulary.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}
