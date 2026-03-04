//
//  StillMomentApp.swift
//  Still Moment
//
//  Created by Helmut Zechmann on 26.10.25.
//

import OSLog
import SwiftUI

/// Tab identifiers for persistence
enum AppTab: String, CaseIterable {
    case timer
    case library
    case settings
}

@main
struct StillMomentApp: App {
    // MARK: Lifecycle

    /// Theme manager - owns theme state, injected as @EnvironmentObject
    @StateObject private var themeManager = ThemeManager()

    /// File open handler - manages "Open with" imports from Files app
    @StateObject private var fileOpenHandler = FileOpenHandler()

    /// Persisted tab selection - remembers last used tab across app launches
    @AppStorage("selectedTab")
    private var selectedTab: String = AppTab.timer.rawValue

    /// Error message from file open handling
    @State private var fileOpenErrorMessage: String?

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
                        Label("tab.library", systemImage: "waveform")
                    }
                    .tag(AppTab.library.rawValue)
                    .accessibilityIdentifier("tab.library")
                    .accessibilityLabel(Text("tab.library.accessibility"))

                    // App Settings Tab
                    NavigationStack {
                        AppSettingsView()
                    }
                    .tabItem {
                        Label("tab.settings", systemImage: "slider.horizontal.3")
                    }
                    .tag(AppTab.settings.rawValue)
                    .accessibilityIdentifier("tab.settings")
                    .accessibilityLabel(Text("tab.settings.accessibility"))
                }
            }
            .environmentObject(self.themeManager)
            .environmentObject(self.fileOpenHandler)
            .onOpenURL { url in
                self.handleFileOpen(url: url)
            }
            .sheet(isPresented: self.$fileOpenHandler.showImportTypeSelection) {
                self.handleImportDismissed()
            } content: {
                ThemeRootView {
                    ImportTypeSelectionView(
                        onTypeSelected: self.handleImportTypeSelection
                    ) { self.fileOpenHandler.showImportTypeSelection = false }
                }
                .environmentObject(self.themeManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert(
                NSLocalizedString("common.error", comment: ""),
                isPresented: Binding(
                    get: { self.fileOpenErrorMessage != nil },
                    set: { if !$0 { self.fileOpenErrorMessage = nil } }
                )
            ) {
                Button(NSLocalizedString("common.ok", comment: "")) {
                    self.fileOpenErrorMessage = nil
                }
            } message: {
                if let errorMessage = fileOpenErrorMessage {
                    Text(errorMessage)
                }
            }
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

    /// Handles a file URL received via "Open with" (CFBundleDocumentTypes)
    ///
    /// Validates the file and shows the import type selection sheet.
    /// The actual import happens when the user selects a type.
    private func handleFileOpen(url: URL) {
        Logger.guidedMeditation.info(
            "Received file open URL",
            metadata: ["file": url.lastPathComponent]
        )
        self.fileOpenHandler.prepareImport(url: url)

        // Show error if format is unsupported (prepareImport silently rejects)
        if !self.fileOpenHandler.showImportTypeSelection {
            self.fileOpenErrorMessage = FileOpenError.unsupportedFormat.localizedDescription
        }
    }

    /// Handles the user's import type selection
    private func handleImportTypeSelection(_ type: ImportAudioType) {
        guard let url = self.fileOpenHandler.pendingImportURL
        else { return }
        self.fileOpenHandler.showImportTypeSelection = false

        Task {
            let result = await self.fileOpenHandler.importFile(from: url, as: type)
            self.fileOpenHandler.pendingImportURL = nil

            switch result {
            case .success(.guidedMeditation):
                self.selectedTab = AppTab.library.rawValue

            case .success(.customAudio):
                // Navigate to Timer tab — TimerView reacts to pendingCustomAudioImport
                self.selectedTab = AppTab.timer.rawValue

            case let .failure(error):
                self.fileOpenErrorMessage = error.localizedDescription
            }
        }
    }

    /// Handles dismissal of the import type selection sheet
    private func handleImportDismissed() {
        self.fileOpenHandler.cancelPendingImport()
    }
}
