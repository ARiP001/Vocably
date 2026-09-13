//
//  PronunciationResult.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation

/// Kategori tingkatan skor pengucapan yang digunakan untuk umpan balik latihan.
enum PronunciationScore {
    case perfect
    case almost
    case keepTrying
    case unrecognized

    var title: String {
        switch self {
        case .perfect:
            return "Great"
        case .almost:
            return "Almost"
        case .keepTrying:
            return "Keep trying"
        case .unrecognized:
            return "Unknown"
        }
    }
}

/// Tingkatan akurasi untuk penilaian kata individual dalam kalimat latihan.
enum WordAccuracy {
    case unassessed
    case accurate
    case acceptable
    case poor

    init(score: Double) {
        switch score {
        case 80...:
            self = .accurate
        case 60..<80:
            self = .acceptable
        default:
            self = .poor
        }
    }
}

/// Token kata yang telah dievaluasi untuk ditampilkan pada antarmuka pengguna.
struct EvaluatedWord: Identifiable {
    let id = UUID()
    let word: String
    let accuracy: WordAccuracy
}

/// Hasil transkrip pengenalan suara dan penilaian skor keseluruhan.
struct PronunciationResult {
    var recognizedText: String = ""
    var score: PronunciationScore = .unrecognized
    /// Skor keseluruhan Azure HundredMark (0...100).
    var overallScore: Double?
    /// Daftar skor yang dihasilkan untuk setiap kata, sesuai urutan pelafalan.
    var words: [PronunciationWordResult] = []
}

/// Penilaian pengucapan untuk kata individual.
struct PronunciationWordResult: Identifiable {
    let id = UUID()
    let word: String
    let score: Double
}
