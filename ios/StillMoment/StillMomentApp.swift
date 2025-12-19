//
//  StillMomentApp.swift
//  Still Moment
//
//  Created by Helmut Zechmann on 26.10.25.
//

import SwiftUI

/// Tab identifiers for persistence
enum AppTab: String, CaseIterable {
    case timer
    case library
}

@main
struct StillMomentApp: App {
    // MARK: Lifecycle

    /// Persisted tab selection - remembers last used tab across app launches
    @AppStorage("selectedTab")
    private var selectedTab: String = AppTab.timer.rawValue

    init() {
        // Configure tab bar appearance with warm colors
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.backgroundSecondary)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: Internal

    var body: some Scene {
        WindowGroup {
            TabView(selection: self.$selectedTab) {
                // Timer Feature Tab
                NavigationStack {
                    TimerView(viewModel: self.createTimerViewModel())
                }
                .tabItem {
                    Label("tab.timer", systemImage: "timer")
                }
                .tag(AppTab.timer.rawValue)
                .accessibilityIdentifier("tab.timer")
                .accessibilityLabel(Text("tab.timer.accessibility"))

                // Guided Meditations Library Tab
                NavigationStack {
                    GuidedMeditationsListView()
                }
                .tabItem {
                    Label("tab.library", systemImage: "music.note.list")
                }
                .tag(AppTab.library.rawValue)
                .accessibilityIdentifier("tab.library")
                .accessibilityLabel(Text("tab.library.accessibility"))
            }
            .tint(.interactive)
            .preferredColorScheme(.light)
        }
    }

    // MARK: Private

    /// Create configured TimerViewModel based on launch arguments
    /// UI tests can override countdown duration via "-CountdownDuration 0"
    private func createTimerViewModel() -> TimerViewModel {
        let countdownDuration = self.getCountdownDuration()
        let timerService = TimerService(countdownDuration: countdownDuration)
        return TimerViewModel(timerService: timerService)
    }

    /// Get countdown duration from launch arguments, defaulting to 15 seconds
    private func getCountdownDuration() -> Int {
        guard let countdownArg = ProcessInfo.processInfo.arguments.firstIndex(of: "-CountdownDuration"),
              countdownArg + 1 < ProcessInfo.processInfo.arguments.count,
              let duration = Int(ProcessInfo.processInfo.arguments[countdownArg + 1])
        else {
            return 15 // Default: 15-second countdown
        }
        return duration
    }
}
