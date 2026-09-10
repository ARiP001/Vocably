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

                Button("See More Definitions") {
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
        .toolbar(.hidden, for: .tabBar)
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
            Text("Meaning \(index + 1)")
                .font(.headline)

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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                ForEach(Array(vocabulary.allDefinitions.enumerated()), id: \.offset) { index, definition in
                    definitionCard(definition, index: index)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vocabulary.word)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vocabulary.word)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(vocabulary.partOfSpeech.capitalized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                if let ipa = vocabulary.pronunciation?.ipa, !ipa.isEmpty {
                    Button {
                        SpeechHelper.speak(vocabulary.word, languageCode: "en-US")
                    } label: {
                        Label(ipa, systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.appSecondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if vocabulary.domain.isEmpty {
                    metadataBadge("General", icon: "globe")
                } else {
                    metadataBadge(vocabulary.domain.joined(separator: " • "), icon: "square.grid.2x2")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func metadataBadge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(Capsule())
    }

    private func definitionCard(_ definition: RecommendedDefinition, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meaning \(index + 1)")
                .font(.headline)

            if let label = definition.label, !label.isEmpty {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .italic()
                    .foregroundStyle(Color.appSecondary)
            }

            if let description = definition.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let examples = definition.examples, !examples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            Text(example)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .background(Color.appSecondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appPrimary)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
