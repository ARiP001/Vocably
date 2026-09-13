//
//  VocabularyDataService.swift
//  LearningSpeakingEnglish
//

import Foundation

/// Errors that can occur when loading bundled vocabulary definitions.
enum VocabularyDataError: LocalizedError {
    case fileNotFound
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Vocabulary resource file 'vocabulary.json' was not found in the application bundle."
        case .decodingFailed(let underlyingError):
            return "Failed to decode 'vocabulary.json': \(underlyingError.localizedDescription)"
        }
    }
}

/// Service responsible for loading bundled vocabulary definitions.
enum VocabularyDataService {
    /// Loads bundled vocabulary definitions, returning a typed Result.
    static func loadVocabulary() -> Result<[RecommendedVocabulary], VocabularyDataError> {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            return .failure(.fileNotFound)
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([RecommendedVocabulary].self, from: data)
            return .success(items)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }

    /// Loads bundled vocabulary definitions. In DEBUG mode, reports failures explicitly via assertion.
    static func load() -> [RecommendedVocabulary] {
        switch loadVocabulary() {
        case .success(let vocabularies):
            return vocabularies
        case .failure(let error):
            assertionFailure("VocabularyDataService failed to load vocabulary: \(error.localizedDescription)")
            return []
        }
    }

    /// Creates an in-memory session populated from bundled vocabulary data.
    @MainActor
    static func createSession(dailyGoal: Int, interest: String = "General") -> LearningSession {
        let vocabulary = load().map(Vocab.init(recommendedVocabulary:))
        return LearningSession(
            dailyGoal: max(1, dailyGoal),
            vocabList: vocabulary,
            selectedInterest: interest
        )
    }
}
