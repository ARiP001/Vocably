//
//  LearnSentenceView.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 15/04/26.
//

import SwiftUI
import AVFoundation

struct LearnSentenceView: View {
    @Binding var session: LearningSession
    var onFlowFinished: () -> Void
    let exampleIndex: Int
    @State var showRecordingSheet = false
    @State var hasRecorded = false
    @State private var goToNextSentence = false
    @State private var goToCompare = false
    @State private var recorder: AVAudioRecorder?
    @State private var recordingSeconds = 0
    @State private var recordingTimer: Timer?
    @State private var isCheckingPronunciation = false
    @State private var pronunciationResult = PronunciationResult()
    @State private var pronunciationError: String?
    @State private var assessmentTask: Task<Void, Never>?
    
    private var activeExample: Example? {
        let examples = session.currentExamples
        guard examples.indices.contains(exampleIndex) else {
            return nil
        }
        return examples[exampleIndex]
    }

    private var currentStep: Int {
        min(exampleIndex + 2, 3)
    }

    private var sentenceTitle: String {
        if exampleIndex == 0 {
            return "Sentence 1"
        }
        return "Sentence 2"
    }

    private var isLastSentenceStep: Bool {
        exampleIndex >= 1
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                LearningStepProgressView(currentStep: currentStep, totalSteps: 3)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

//                Color.clear
//                    .frame(height: 16)

                VStack(spacing: 14) {
                    Text("Practice \(sentenceTitle)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    sentenceText

                    Button {
                        SpeechHelper.speak(activeExample?.exampleEN ?? "", languageCode: "en-US")
                    } label: {
                        HStack(spacing: 8) {
                            Text("Listen")
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
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()

                if hasRecorded || isCheckingPronunciation {
                    pronunciationFeedbackCard
                        .padding(.bottom, 14)
                }

                ZStack {
                    Button {
                        startRecording()
                    } label: {
                        Image(systemName: "microphone")
                            .font(.largeTitle)
                            .frame(width: 100, height: 100)
                            .background(Color.appPrimary)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }

                    HStack {
                        if hasRecorded {
                            Button {
                                if let url = session.recordingURL(forStep: currentStep) {
                                    RecordingPlaybackHelper.play(url: url)
                                } else {
                                    SpeechHelper.speak(activeExample?.exampleEN ?? "", languageCode: "en-US")
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .font(.title3)
                                    .frame(width: 60, height: 60)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .padding(.leading, 20)
                                    .foregroundStyle(Color.appPrimary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .padding(.horizontal)

            if hasRecorded {
                VStack {
                    Spacer()

                    VStack {
                        Button {
                            if isLastSentenceStep {
                                goToCompare = true
                            } else {
                                goToNextSentence = true
                            }
                        } label: {
                            Text("Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle(sentenceTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToNextSentence) {
            LearnSentenceView(
                session: $session,
                onFlowFinished: onFlowFinished,
                exampleIndex: exampleIndex + 1
            )
        }
        .navigationDestination(isPresented: $goToCompare) {
            CompareView(session: $session, onFlowFinished: onFlowFinished)
        }
        .sheet(isPresented: $showRecordingSheet) {
            RecordingSheetView(
                showRecordingSheet: $showRecordingSheet,
                recordingTitle: sentenceTitle,
                recordingHint: "Speak naturally and clearly",
                recordingSeconds: recordingSeconds,
                onStopRecording: stopRecording
            )
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(true)
        }
        .alert("Pronunciation check failed", isPresented: Binding(
            get: { pronunciationError != nil },
            set: { if !$0 { pronunciationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pronunciationError ?? "Please try recording again.")
        }
        .onDisappear {
            assessmentTask?.cancel()
            isCheckingPronunciation = false
        }
    }

    private func startRecording() {
        RecordingHelper.requestMicrophonePermission { granted in
            guard granted else { return }

            do {
                let fileName = "sentence-\(currentStep)-\(UUID().uuidString).wav"
                let newRecorder = try RecordingHelper.makeRecorder(fileName: fileName)
                recorder = newRecorder
                recordingSeconds = 0
                newRecorder.record()

                recordingTimer?.invalidate()
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    recordingSeconds += 1
                }

                withAnimation(.easeInOut(duration: 0.3)) {
                    showRecordingSheet = true
                }
            } catch {
                recorder = nil
            }
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        if let fileURL = recorder?.url {
            hasRecorded = true
            session.saveRecording(forStep: currentStep, fileURL: fileURL)
            analyzePronunciation(fileURL: fileURL)
        }

        recorder = nil
        showRecordingSheet = false
    }

    private func analyzePronunciation(fileURL: URL) {
        pronunciationResult = PronunciationResult()
        pronunciationError = nil
        isCheckingPronunciation = true

        let targetSentence = activeExample?.exampleEN ?? ""
        assessmentTask?.cancel()
        assessmentTask = Task { @MainActor in
            do {
                guard let service = PronunciationService.configured else {
                    throw PronunciationServiceError.missingConfiguration
                }
                pronunciationResult = try await service.assess(fileURL: fileURL, referenceText: targetSentence)
                session.savePronunciationResult(forStep: currentStep, result: pronunciationResult)
            } catch {
                if Task.isCancelled { return }
                pronunciationResult = PronunciationResult()
                pronunciationError = error.localizedDescription
                print("Azure pronunciation assessment failed: \(error)")
            }
            isCheckingPronunciation = false
            assessmentTask = nil
        }
    }

    private var pronunciationFeedbackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pronunciation check")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)

                Spacer()

                if isCheckingPronunciation {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(scoreLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(pronunciationResult.score.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(pronunciationResult.score.color.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if !pronunciationResult.recognizedText.isEmpty {
                Text("Detected: \(pronunciationResult.recognizedText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var scoreLabel: String {
        guard let percentage = pronunciationResult.percentage else {
            return "--/100"
        }
        return "\(pronunciationResult.score.title) · PronScore: \(Int(percentage.rounded()))/100"
    }

    private var sentenceText: some View {
        let words = (activeExample?.exampleEN ?? "No sentence").split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        let sentence = words.enumerated().reduce(Text("")) { result, element in
            let (index, word) = element
            let wordText = Text(word)
                .font(.title)
                .foregroundColor(pronunciationColor(for: index) ?? .primary)
            return result + (index == 0 ? wordText : Text(" ") + wordText)
        }
        return sentence.multilineTextAlignment(.center)
    }

    private func pronunciationColor(for index: Int) -> Color? {
        if pronunciationResult.words.indices.contains(index) {
            return pronunciationResult.words[index].color
        }

        // Some Azure responses include the overall HundredMark score but omit
        // the Words array. Keep the per-word UI visible using recognized text
        // as a fallback instead of silently showing an uncolored sentence.
        guard let percentage = pronunciationResult.percentage else { return nil }
        let targetWords = (activeExample?.exampleEN ?? "")
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.lowercased() }
        guard targetWords.indices.contains(index) else { return .red }

        let recognizedWords = pronunciationResult.recognizedText
            .split(whereSeparator: { !$0.isLetter })
            .map { $0.lowercased() }
        return recognizedWords.contains(targetWords[index])
            ? PronunciationWordResult(word: targetWords[index], score: percentage).color
            : .red
    }

}
#Preview{
    NavigationStack {
        LearnSentenceView(
            session: .constant(LearningSession.placeholder(dailyGoal: 3)),
            onFlowFinished: {},
            exampleIndex: 0
        )
    }
}
