//
//  LearnSheet.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 14/04/26.
//

import SwiftUI
import AVFoundation

struct LearnVocabView: View {
    @Binding var session: LearningSession
    var onFlowFinished: () -> Void
    @State var showRecordingSheet = false
    @State var hasRecorded = false
    @State var goToNext = false
    @State private var recorder: AVAudioRecorder?
    @State private var recordingSeconds = 0
    @State private var recordingTimer: Timer?
    @State private var justRecordedURL: URL?
    @State private var isCheckingPronunciation = false
    @State private var pronunciationResult = PronunciationResult()
    @State private var pronunciationError: String?
    @State private var showExitAlert = false
    @State private var assessmentTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                LearningStepProgressView(currentStep: 1, totalSteps: 3)
                    .padding(.top, 8)
                    .padding (.bottom, 20)

//                Spacer()
                VStack(spacing: 14) {
                    Text("Say this word clearly")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(session.currentVocab?.nameEN ?? "Vocabulary")
                        .font(.system(size: 40, weight: .bold))

                    HStack {
                        Button {
                            SpeechHelper.speak(session.currentVocab?.nameEN ?? "", languageCode: "en-US")
                        } label: {
                            HStack(spacing: 8) {
                                Text(session.currentVocab?.pronoun ?? "-")
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
//                            .glassEffect()
                            .background(Color.appPrimary)
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                    }
                    HStack {
                        if hasRecorded {
                            Button {
                                if let url = session.recordingURL(forStep: 1) {
                                    RecordingPlaybackHelper.play(url: url)
                                } else {
                                    SpeechHelper.speak(session.currentVocab?.nameEN ?? "", languageCode: "en-US")
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .frame(width: 50, height: 50)
                                    .glassEffect()
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .foregroundStyle(Color.appPrimary)
                                    .padding(.leading, 40)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)

//                if hasRecorded || isCheckingPronunciation {
//                    pronunciationFeedbackCard
//                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal)

            if hasRecorded {
                VStack {
                    Spacer()

                    VStack {
                        Button {
                            goToNext = true
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
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Vocab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showExitAlert = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)
                }
            }
        }
        .alert("Exit learning session?", isPresented: $showExitAlert) {
            Button("Stay", role: .cancel) {}
            Button("Exit", role: .destructive) {
                onFlowFinished()
            }
        } message: {
            Text("Your current learning progress will not be saved.")
        }
        .navigationDestination(isPresented: $goToNext) {
            LearnSentenceView(
                session: $session,
                onFlowFinished: onFlowFinished,
                exampleIndex: 0
            )
        }
        .sheet(isPresented: $showRecordingSheet) {
            RecordingSheetView(
                showRecordingSheet: $showRecordingSheet,
                recordingTitle: "Recording vocab",
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
                let fileName = "vocab-\(UUID().uuidString).wav"
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
            justRecordedURL = fileURL
            hasRecorded = true
            session.saveRecording(forStep: 1, fileURL: fileURL)
            analyzePronunciation(fileURL: fileURL)
        }

        recorder = nil
        showRecordingSheet = false
    }

    private func analyzePronunciation(fileURL: URL) {
        pronunciationResult = PronunciationResult()
        pronunciationError = nil
        isCheckingPronunciation = true

        let targetWord = session.currentVocab?.nameEN ?? ""
        assessmentTask?.cancel()
        assessmentTask = Task { @MainActor in
            do {
                guard let service = PronunciationService.configured else {
                    throw PronunciationServiceError.missingConfiguration
                }
                pronunciationResult = try await service.assess(fileURL: fileURL, referenceText: targetWord)
                session.savePronunciationResult(forStep: 1, result: pronunciationResult)
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
                    Text(pronunciationResult.score.title + (pronunciationResult.percentage.map { " · PronScore: \(Int($0.rounded()))/100" } ?? ""))
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

#Preview {
    NavigationStack {
        LearnVocabView(
            session: .constant(LearningSession.placeholder(dailyGoal: 3)),
            onFlowFinished: {}
        )
    }
    
}
