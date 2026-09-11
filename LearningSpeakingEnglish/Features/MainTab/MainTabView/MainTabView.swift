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
    @State private var viewModel: MainTabViewModel

    init(dailyGoal: Int, interest: String, userName: String) {
        self.dailyGoal = dailyGoal
        self.interest = interest
        self.userName = userName
        _viewModel = State(initialValue: MainTabViewModel(dailyGoal: dailyGoal, interest: interest))
    }

    var body: some View {
        TabView {
            MissionHomeView(userName: userName, selectedDomain: interest, session: $viewModel.session)
                .tabItem {
                    Label {
                        Text("Mission")
                    } icon: {
                        Image.mission
                    }
                }

            ListView(session: $viewModel.session, selectedDomain: interest)
                .tabItem {
                    Label {
                        Text("List")
                    } icon: {
                        Image.list
                    }
                }
            
            SettingView()
                .tabItem {
                    Label {
                        Text("Setting")
                    } icon: {
                        Image.settings
                    }
                }
        }
        .onChange(of: dailyGoal) { _, newGoal in
            viewModel.updateDailyGoal(newGoal)
        }
        .onChange(of: interest) { _, newInterest in
            viewModel.updateInterest(newInterest)
        }
        .onAppear {
            guard !viewModel.hasRestoredProgress else { return }
            viewModel.hasRestoredProgress = true
            ProgressPersistenceService.restore(session: &viewModel.session, from: progressStores, in: modelContext)
        }
        .onChange(of: viewModel.session.learnedVocabIDs) { _, _ in
            guard viewModel.hasRestoredProgress else { return }
            ProgressPersistenceService.persist(session: viewModel.session, to: progressStores, in: modelContext)
        }
        .onChange(of: viewModel.session.currentIndex) { _, _ in
            guard viewModel.hasRestoredProgress else { return }
            ProgressPersistenceService.persist(session: viewModel.session, to: progressStores, in: modelContext)
        }
    }
}

#Preview {
    MainTabView(
        dailyGoal: AppDefaults.defaultDailyGoal,
        interest: AppDefaults.defaultInterest,
        userName: AppDefaults.fallbackLearnerName
    )
}
