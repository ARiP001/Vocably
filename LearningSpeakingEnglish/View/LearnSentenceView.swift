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

                    Text(activeExample?.exampleEN ?? "No sentence")
                        .font(.title)
                        .multilineTextAlignment(.center)

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
    }

    private func startRecording() {
        RecordingHelper.requestMicrophonePermission { granted in
            guard granted else { return }

            do {
                let fileName = "sentence-\(currentStep)-\(UUID().uuidString).m4a"
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
        isCheckingPronunciation = true

        let targetSentence = activeExample?.exampleEN ?? ""
        PronunciationHelper.requestSpeechPermission { granted in
            guard granted else {
                isCheckingPronunciation = false
                return
            }

            PronunciationHelper.analyze(from: fileURL, targetText: targetSentence) { result in
                pronunciationResult = result
                isCheckingPronunciation = false
            }
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
                    Text(pronunciationResult.score.title)
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
