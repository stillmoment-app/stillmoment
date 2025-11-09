//
//  StillMomentApp.swift
//  Still Moment
//
//  Created by Helmut Zechmann on 26.10.25.
//

import SwiftUI

@main
struct StillMomentApp: App {
    // MARK: Internal

    var body: some Scene {
        WindowGroup {
            TabView {
                // Timer Feature Tab
                NavigationStack {
                    TimerView(viewModel: self.createTimerViewModel())
                }
                .tabItem {
                    Label("tab.timer", systemImage: "timer")
                }
                .accessibilityIdentifier("tab.timer")
                .accessibilityLabel(Text("tab.timer.accessibility"))

                // Guided Meditations Library Tab
                NavigationStack {
                    GuidedMeditationsListView()
                }
                .tabItem {
                    Label("tab.library", systemImage: "music.note.list")
                }
                .accessibilityIdentifier("tab.library")
                .accessibilityLabel(Text("tab.library.accessibility"))
            }
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
