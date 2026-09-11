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
    @State private var viewModel: CuratedMissionDetailViewModel

    init(
        vocabulary: RecommendedVocabulary,
        selectedDomain: String,
        onFinished: @escaping () -> Void
    ) {
        self.vocabulary = vocabulary
        self.selectedDomain = selectedDomain
        self.onFinished = onFinished
        _viewModel = State(initialValue: CuratedMissionDetailViewModel(vocabulary: vocabulary))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                vocabularyCard

                if viewModel.personalizationStatus == .loading {
                    personalizationLoadingCard
                }

                ForEach(Array(viewModel.content.definitions.enumerated()), id: \.offset) { index, definition in
                    definitionCard(definition, index: index)
                }

                Button("See More Definitions") {
                    viewModel.showFullDetails = true
                }
                .font(.subheadSemibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.bgSecondary)
                .foregroundStyle(Color.brandPrimary)
                .clipShape(Capsule())

                PrimaryButton(title: "Speak Now") {
                    viewModel.showSpeakingPractice = true
                }

            }
            .padding()
        }
        .background(Color.bgPrimary)
        .navigationTitle("Mission Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $viewModel.showFullDetails) {
            FullVocabularyDetailView(vocabulary: vocabulary)
        }
        .navigationDestination(isPresented: $viewModel.showSpeakingPractice) {
            PersonalizedSpeakingPracticeView(
                word: vocabulary.word,
                sentences: viewModel.practiceSentences,
                onFinished: {
                    viewModel.showSpeakingPractice = false
                    onFinished()
                }
            )
        }
        .alert("Personalized content unavailable", isPresented: $viewModel.showPersonalizationAlert) {
            Button("Continue with dictionary content", role: .cancel) {}
        } message: {
            Text("Vocab.ly could not prepare personalized examples or Indonesian translations right now. You can continue with the original vocabulary content.")
        }
        .task(id: "\(vocabulary.id)-\(selectedDomain)") {
            await viewModel.loadPersonalizedContent(
                vocabulary: vocabulary,
                selectedDomain: selectedDomain,
                caches: personalizationCaches,
                modelContext: modelContext
            )
        }
    }

    private var personalizationLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.brandPrimary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Preparing your lesson")
                    .font(.subheadSemibold)
                Text("Selecting useful meanings and creating practice content…")
                    .font(.caption1Regular)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var vocabularyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(vocabulary.word)
                        .font(.largeTitleBold)
                    Text(viewModel.content.translation?.word ?? "")
                        .font(.title3Bold)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let ipa = vocabulary.pronunciation?.ipa {
                    ListenAudioButton(title: ipa) {
                        viewModel.speak(text: vocabulary.word)
                    }
                }
            }

            HStack(spacing: 7) {
                Text(vocabulary.partOfSpeech)
                if let translation = viewModel.content.translation?.partOfSpeech, !translation.isEmpty {
                    Text("•")
                    Text(translation)
                }
            }
            .font(.subheadRegular)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func definitionCard(_ definition: RecommendedDefinition, index: Int) -> some View {
        let examples = viewModel.content.generatedExamples.indices.contains(index) ? viewModel.content.generatedExamples[index] : []
        let translations = viewModel.content.translation?.examples.indices.contains(index) == true
            ? viewModel.content.translation?.examples[index] ?? []
            : []
        let definitionTranslation = viewModel.content.translation?.definitions.indices.contains(index) == true
            ? viewModel.content.translation?.definitions[index]
            : nil

        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Meaning \(index + 1)")
                .font(.headlineRegular)

            if let label = definition.label {
                Text(label)
                    .font(.caption1Regular)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            if let description = definition.description {
                Text(description)
                    .font(.bodyRegular)
            }

            if let definitionTranslation, !definitionTranslation.isEmpty {
                Text(definitionTranslation)
                    .font(.bodyRegular)
                    .foregroundStyle(.secondary)
            }

            if !examples.isEmpty {
                Divider()
                Text("Practice in \(selectedDomain)")
                    .font(.subheadSemibold)
                    .foregroundStyle(Color.brandSecondary)

                ForEach(Array(examples.enumerated()), id: \.offset) { exampleIndex, example in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Button {
                                viewModel.speak(text: example)
                            } label: {
                                Image.speaker
                                    .foregroundStyle(Color.brandSecondary)
                            }
                            .buttonStyle(.plain)
                            Text(example)
                        }
                        if translations.indices.contains(exampleIndex), !translations[exampleIndex].isEmpty {
                            Text(translations[exampleIndex])
                                .font(.subheadRegular)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 27)
                        }
                    }
                    .padding(12)
                    .background(Color.brandSecondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

/// Full, uncurated dictionary reference exposed from the mission's See More action.
struct FullVocabularyDetailView: View {
    let vocabulary: RecommendedVocabulary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                headerCard

                ForEach(Array(vocabulary.allDefinitions.enumerated()), id: \.offset) { index, definition in
                    definitionCard(definition, index: index)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bgPrimary)
        .navigationTitle(vocabulary.word)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vocabulary.word)
                        .font(.largeTitleBold)
                    Text(vocabulary.partOfSpeech.capitalized)
                        .font(.subheadMedium)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                if let ipa = vocabulary.pronunciation?.ipa, !ipa.isEmpty {
                    Button {
                        SpeechHelper.speak(vocabulary.word, languageCode: "en-US")
                    } label: {
                        Label {
                            Text(ipa)
                        } icon: {
                            Image.speaker
                        }
                            .font(.subheadMedium)
                            .foregroundStyle(Color.brandSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.brandSecondary.opacity(0.12))
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
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    private func metadataBadge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption1Medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(Capsule())
    }

    private func definitionCard(_ definition: RecommendedDefinition, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Meaning \(index + 1)")
                .font(.headlineRegular)

            if let label = definition.label, !label.isEmpty {
                Text(label)
                    .font(.subheadSemibold)
                    .italic()
                    .foregroundStyle(Color.brandSecondary)
            }

            if let description = definition.description, !description.isEmpty {
                Text(description)
                    .font(.bodyRegular)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let examples = definition.examples, !examples.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Examples")
                        .font(.caption1Bold)
                        .foregroundStyle(.secondary)

                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image.quoteOpening
                                .font(.caption1Regular)
                                .foregroundStyle(Color.brandSecondary)
                            Text(example)
                                .font(.subheadRegular)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .background(Color.brandSecondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgSecondary)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.brandPrimary)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}
