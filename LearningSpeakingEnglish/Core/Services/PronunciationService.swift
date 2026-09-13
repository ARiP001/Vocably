//
//  PronunciationService.swift
//  LearningSpeakingEnglish
//

import Foundation

enum PronunciationServiceError: LocalizedError {
    case missingConfiguration
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Azure Speech is not configured."
        case .invalidResponse:
            return "The pronunciation service returned an invalid response."
        case .httpError(let statusCode):
            return "The pronunciation service returned HTTP \(statusCode)."
        case .emptyResult:
            return "The pronunciation service returned no pronunciation result."
        }
    }
}

private struct PronunciationAssessmentConfig: Encodable {
    let referenceText: String
    let gradingSystem: String
    let granularity: String
    let dimension: String

    enum CodingKeys: String, CodingKey {
        case referenceText = "ReferenceText"
        case gradingSystem = "GradingSystem"
        case granularity = "Granularity"
        case dimension = "Dimension"
    }

    func base64Encoded() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }
}

private struct AzurePronunciationResponse: Decodable {
    let nBest: [AzureBestResult]

    enum CodingKeys: String, CodingKey {
        case nBest = "NBest"
    }
}

private struct AzureBestResult: Decodable {
    let display: String?
    let lexical: String?
    let accuracyScore: Double?
    let fluencyScore: Double?
    let completenessScore: Double?
    let pronunciationScore: Double?
    let pronunciationAssessment: AzurePronunciationAssessment?
    let words: [AzureWordResult]?

    enum CodingKeys: String, CodingKey {
        case display = "Display"
        case lexical = "Lexical"
        case accuracyScore = "AccuracyScore"
        case fluencyScore = "FluencyScore"
        case completenessScore = "CompletenessScore"
        case pronunciationScore = "PronScore"
        case pronunciationAssessment = "PronunciationAssessment"
        case words = "Words"
    }
}

private struct AzurePronunciationAssessment: Decodable {
    let accuracyScore: Double?
    let fluencyScore: Double?
    let completenessScore: Double?
    let pronunciationScore: Double?

    enum CodingKeys: String, CodingKey {
        case accuracyScore = "AccuracyScore"
        case fluencyScore = "FluencyScore"
        case completenessScore = "CompletenessScore"
        case pronunciationScore = "PronScore"
    }
}

private struct AzureWordResult: Decodable {
    let word: String?
    let accuracyScore: Double?
    let pronunciationAssessment: AzurePronunciationAssessment?

    enum CodingKeys: String, CodingKey {
        case word = "Word"
        case accuracyScore = "AccuracyScore"
        case pronunciationAssessment = "PronunciationAssessment"
    }
}

/// Sends 16 kHz PCM WAV recordings to Azure Speech Pronunciation Assessment.
struct PronunciationService {
    let endpoint: URL
    let apiKey: String

    static var configured: PronunciationService? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "AZURE_SPEECH_KEY") as? String,
              let region = Bundle.main.object(forInfoDictionaryKey: "AZURE_SPEECH_REGION") as? String,
              !key.isEmpty,
              !region.isEmpty,
              let endpoint = URL(string: "https://\(region).stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1") else {
            return nil
        }
        return PronunciationService(endpoint: endpoint, apiKey: key)
    }

    func assess(
        audioData: Data,
        referenceText: String
    ) async throws -> PronunciationResult {
        let request = try makeRequest(audioData: audioData, referenceText: referenceText)
        let data = try await execute(request: request)
        let best = try decodeBestResult(from: data)
        return mapToPronunciationResult(best)
    }

    private func makeRequest(audioData: Data, referenceText: String) throws -> URLRequest {
        let assessment = PronunciationAssessmentConfig(
            referenceText: referenceText,
            gradingSystem: "HundredMark",
            granularity: "Word",
            dimension: "Comprehensive"
        )

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "format", value: "detailed")
        ]
        guard let requestURL = components?.url else {
            throw PronunciationServiceError.invalidResponse
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("audio/wav; codecs=audio/pcm; samplerate=16000", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(try assessment.base64Encoded(), forHTTPHeaderField: "Pronunciation-Assessment")
        request.httpBody = audioData
        return request
    }

    private func execute(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PronunciationServiceError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw PronunciationServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        return data
    }

    private func decodeBestResult(from data: Data) throws -> AzureBestResult {
        let decoded = try JSONDecoder().decode(AzurePronunciationResponse.self, from: data)
        guard let best = decoded.nBest.first else {
            throw PronunciationServiceError.emptyResult
        }
        return best
    }

    private func mapToPronunciationResult(_ best: AzureBestResult) -> PronunciationResult {
        let score = best.pronunciationAssessment?.pronunciationScore
            ?? best.pronunciationScore
            ?? best.accuracyScore
            ?? 0

        return PronunciationResult(
            recognizedText: best.display ?? best.lexical ?? "",
            score: Self.score(for: score),
            overallScore: score,
            words: mapWordResults(best.words)
        )
    }

    private func mapWordResults(_ words: [AzureWordResult]?) -> [PronunciationWordResult] {
        (words ?? []).compactMap { word in
            guard let text = word.word,
                  let accuracy = word.pronunciationAssessment?.accuracyScore ?? word.accuracyScore else { return nil }
            return PronunciationWordResult(word: text, score: accuracy)
        }
    }

    func assess(
        fileURL: URL,
        referenceText: String
    ) async throws -> PronunciationResult {
        try await assess(audioData: Data(contentsOf: fileURL), referenceText: referenceText)
    }

    private static func score(for value: Double) -> PronunciationScore {
        switch value {
        case 85...:
            return .perfect
        case 65..<85:
            return .almost
        case 0..<65:
            return .keepTrying
        default:
            return .unrecognized
        }
    }
}
