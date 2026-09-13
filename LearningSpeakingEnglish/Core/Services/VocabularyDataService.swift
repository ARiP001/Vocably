//
//  VocabularyDataService.swift
//  LearningSpeakingEnglish
//

import Foundation

/// Jenis error yang dapat terjadi saat memuat data kosakata bawaan.
enum VocabularyDataError: LocalizedError {
    case fileNotFound
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File sumber kosakata 'vocabulary.json' tidak ditemukan di dalam bundle aplikasi."
        case .decodingFailed(let underlyingError):
            return "Gagal melakukan decode pada 'vocabulary.json': \(underlyingError.localizedDescription)"
        }
    }
}

/// Layanan yang bertanggung jawab memuat data definisi kosakata bawaan aplikasi.
enum VocabularyDataService {
    /// Memuat definisi kosakata bawaan dan mengembalikan Result bertipe.
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

    /// Memuat definisi kosakata bawaan. Dalam mode DEBUG, melaporkan kegagalan secara eksplisit melalui assertion.
    static func load() -> [RecommendedVocabulary] {
        switch loadVocabulary() {
        case .success(let vocabularies):
            return vocabularies
        case .failure(let error):
            // Fail-fast saat tahap pengembangan agar file bundle yang hilang atau ketidaksesuaian skema JSON
            // langsung terdeteksi seketika, namun tetap mengembalikan array kosong saat produksi agar aplikasi tidak crash.
            #if DEBUG
            assertionFailure("VocabularyDataService failed to load vocabulary: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Membuat sesi belajar di memori yang diisi dari data kosakata bawaan.
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
