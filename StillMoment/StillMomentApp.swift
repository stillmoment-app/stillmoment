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
                .accessibilityLabel(Text("tab.timer.accessibility"))

                // Guided Meditations Library Tab
                NavigationStack {
                    GuidedMeditationsListView()
                }
                .tabItem {
                    Label("tab.library", systemImage: "music.note.list")
                }
                .accessibilityLabel(Text("tab.library.accessibility"))
            }
        }
    }

    // MARK: Private

    /// Create configured TimerViewModel based on launch arguments
    /// UI tests can override countdown duration via "-CountdownDuration 0"
    private func createTimerViewModel() -> TimerViewModel {
        // Check for countdown duration override (used by UI tests)
        // swiftlint:disable opening_brace
        let countdownDuration: Int = if let countdownArg = ProcessInfo.processInfo.arguments
            .firstIndex(of: "-CountdownDuration"),
            countdownArg + 1 < ProcessInfo.processInfo.arguments.count,
            let duration = Int(ProcessInfo.processInfo.arguments[countdownArg + 1])
        {
            duration
        } else {
            15 // Default: 15-second countdown
        }
        // swiftlint:enable opening_brace

        // Create timer service with configured countdown duration
        let timerService = TimerService(countdownDuration: countdownDuration)
        return TimerViewModel(timerService: timerService)
    }
}
