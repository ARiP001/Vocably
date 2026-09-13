//
//  PersonalizedVocabularyCache.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 11/09/26.
//

import Foundation
import SwiftData

/// Cache SwiftData untuk menyimpan hasil personalisasi konten AI dari kosakata kamus.
@Model
final class PersonalizedVocabularyCache {
    var cacheKey: String
    var word: String
    var domain: String
    var promptVersion: String
    var modelVersion: String
    var selectedDefinitionIndexes: [Int]
    var generatedExamplesJSON: String
    var translationJSON: String
    var generatedAt: Date

    init(
        cacheKey: String,
        word: String,
        domain: String,
        promptVersion: String,
        modelVersion: String,
        selectedDefinitionIndexes: [Int] = [],
        generatedExamplesJSON: String,
        translationJSON: String,
        generatedAt: Date = .now
    ) {
        self.cacheKey = cacheKey
        self.word = word
        self.domain = domain
        self.promptVersion = promptVersion
        self.modelVersion = modelVersion
        self.selectedDefinitionIndexes = selectedDefinitionIndexes
        self.generatedExamplesJSON = generatedExamplesJSON
        self.translationJSON = translationJSON
        self.generatedAt = generatedAt
    }
}

/// Objek data transfer (DTO) untuk serialisasi terjemahan bahasa Indonesia di penyimpanan cache.
struct CachedIndonesianTranslation: Codable {
    let word: String
    let partOfSpeech: String
    let definitions: [String]
    let examples: [[String]]
}
