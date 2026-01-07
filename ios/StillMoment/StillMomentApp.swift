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

        // Seed test fixtures for screenshot automation (Screenshots target only)
        #if SCREENSHOTS_BUILD
        TestFixtureSeeder.seedIfNeeded(service: GuidedMeditationService())
        #endif
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
    /// UI tests can override preparation time via "-PreparationTimeSeconds 0" or disable it with "-DisablePreparation"
    private func createTimerViewModel() -> TimerViewModel {
        self.applyLaunchArgumentSettings()
        return TimerViewModel()
    }

    /// Apply launch argument overrides to UserDefaults
    /// This allows UI tests to configure preparation time behavior
    private func applyLaunchArgumentSettings() {
        let arguments = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard

        // Check for disable preparation flag
        if arguments.contains("-DisablePreparation") {
            defaults.set(false, forKey: MeditationSettings.Keys.preparationTimeEnabled)
            return
        }

        // Check for custom preparation time (supports both new and legacy argument names)
        var preparationSeconds: Int?

        if let prepArg = arguments.firstIndex(of: "-PreparationTimeSeconds"),
           prepArg + 1 < arguments.count,
           let duration = Int(arguments[prepArg + 1]) {
            preparationSeconds = duration
        } else if let countdownArg = arguments.firstIndex(of: "-CountdownDuration"),
                  countdownArg + 1 < arguments.count,
                  let duration = Int(arguments[countdownArg + 1]) {
            preparationSeconds = duration
        }

        if let seconds = preparationSeconds {
            if seconds == 0 {
                // Zero means disable preparation
                defaults.set(false, forKey: MeditationSettings.Keys.preparationTimeEnabled)
            } else {
                defaults.set(true, forKey: MeditationSettings.Keys.preparationTimeEnabled)
                defaults.set(seconds, forKey: MeditationSettings.Keys.preparationTimeSeconds)
            }
        }
    }
}
