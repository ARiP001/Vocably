//
//  FullVocabularyDetailView.swift
//  LearningSpeakingEnglish
//

import SwiftUI

/// Referensi kamus lengkap tanpa kurasi yang ditampilkan dari aksi "See More" pada detail misi.
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
                        SpeechService.speak(vocabulary.word, languageCode: "en-US")
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
