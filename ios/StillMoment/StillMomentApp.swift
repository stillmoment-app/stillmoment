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

    /// Theme manager - owns theme state, injected as @EnvironmentObject
    @StateObject private var themeManager = ThemeManager()

    /// Persisted tab selection - remembers last used tab across app launches
    @AppStorage("selectedTab")
    private var selectedTab: String = AppTab.timer.rawValue

    init() {
        // Seed test fixtures for screenshot automation (Screenshots target only)
        #if SCREENSHOTS_BUILD
        TestFixtureSeeder.seedIfNeeded(service: GuidedMeditationService())
        #endif
    }

    // MARK: Internal

    var body: some Scene {
        WindowGroup {
            ThemeRootView {
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
            }
            .environmentObject(self.themeManager)
        }
    }

    // MARK: Private

    /// Create configured TimerViewModel
    /// UI tests can disable preparation time via "-DisablePreparation" launch argument
    private func createTimerViewModel() -> TimerViewModel {
        self.applyLaunchArgumentSettings()
        return TimerViewModel()
    }

    /// Apply launch argument overrides to UserDefaults
    /// This allows UI tests to configure preparation time behavior
    private func applyLaunchArgumentSettings() {
        // Check for disable preparation flag (used by UI tests and screenshot automation)
        if ProcessInfo.processInfo.arguments.contains("-DisablePreparation") {
            PreparationTimeConfigurer.disable()
        }
    }
}
