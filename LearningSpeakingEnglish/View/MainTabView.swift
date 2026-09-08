//
//  MainTabView.swift
//  LearningSpeakingEnglish
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    let dailyGoal: Int
    let interest: String
    let userName: String
    @Environment(\.modelContext) private var modelContext
    @Query private var progressStores: [LearningProgressStore]
    @State private var session: LearningSession
    @State private var hasRestoredProgress = false

    init(dailyGoal: Int, interest: String, userName: String) {
        self.dailyGoal = dailyGoal
        self.interest = interest
        self.userName = userName
        _session = State(initialValue: LearningSession.placeholder(dailyGoal: dailyGoal, interest: interest))
    }

    var body: some View {
        TabView {
            MissionHomeView(userName: userName, selectedDomain: interest, session: $session)
                .tabItem {
                    Label("Mission", systemImage: "target")
                }

            ListView(session: $session, selectedDomain: interest)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            
            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }
        }
        .onChange(of: dailyGoal) { _, newGoal in
            session.dailyGoal = max(1, newGoal)
        }
        .onChange(of: interest) { _, newInterest in
            session.selectedInterest = newInterest
        }
        .onAppear {
            restoreProgressIfNeeded()
        }
        .onChange(of: session.learnedVocabIDs) { _, _ in
            persistProgress()
        }
        .onChange(of: session.currentIndex) { _, _ in
            persistProgress()
        }
    }

    private var progressStore: LearningProgressStore {
        if let existing = progressStores.first(where: { $0.singletonKey == "main-progress" }) {
            return existing
        }

        let created = LearningProgressStore()
        modelContext.insert(created)
        return created
    }

    private func restoreProgressIfNeeded() {
        guard !hasRestoredProgress else { return }
        hasRestoredProgress = true

        let store = progressStore
        let learnedNames = store.learnedVocabNamesCSV
            .split(separator: ",")
            .map { String($0) }

        let restoredLearnedIDs = session.vocabList
            .filter { learnedNames.contains($0.nameEN) }
            .map { $0.id }
        session.learnedVocabIDs = restoredLearnedIDs

        if !store.currentVocabName.isEmpty,
           let restoredIndex = session.vocabList.firstIndex(where: { $0.nameEN == store.currentVocabName }) {
            session.currentIndex = restoredIndex
        }
    }

    private func persistProgress() {
        guard hasRestoredProgress else { return }

        let store = progressStore
        let learnedNames = session.vocabList
            .filter { session.learnedVocabIDs.contains($0.id) }
            .map { $0.nameEN }
        store.learnedVocabNamesCSV = learnedNames.joined(separator: ",")
        store.currentVocabName = session.currentVocab?.nameEN ?? ""

        do {
            try modelContext.save()
        } catch {
            // Keep app usable even when persistence fails.
        }
    }
}

#Preview {
    MainTabView(dailyGoal: 3, interest: "General", userName: "Himmel")
}
