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

    /// File open handler - manages "Open with" and Share Extension imports
    @StateObject private var fileOpenHandler: FileOpenHandler

    /// Inbox handler - processes Share Extension inbox entries
    @StateObject private var inboxHandler: InboxHandler

    /// Persisted tab selection - remembers last used tab across app launches
    @AppStorage("selectedTab")
    private var selectedTab: String = AppTab.timer.rawValue

    /// Navigation path for library tab (enables programmatic navigation)
    @State private var libraryPath = NavigationPath()

    /// Error message from file open handling
    @State private var fileOpenErrorMessage: String?

    /// Scene phase for inbox polling
    @Environment(\.scenePhase)
    private var scenePhase

    init() {
        let fileOpenHandler = FileOpenHandler()
        let inboxDir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.stillmoment")?
            .appendingPathComponent("ShareInbox")
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("ShareInbox")

        _fileOpenHandler = StateObject(wrappedValue: fileOpenHandler)
        _inboxHandler = StateObject(wrappedValue: InboxHandler(
            fileOpenHandler: fileOpenHandler,
            downloadService: AudioDownloadService(),
            inboxDirectoryURL: inboxDir
        ))

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
                    NavigationStack(path: self.$libraryPath) {
                        GuidedMeditationsListView(navigationPath: self.$libraryPath)
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
                self.handleOpenURL(url: url)
            }
            // iOS 16 signature — update to (oldValue, newValue) when dropping iOS 16
            .onChange(of: self.scenePhase) { newPhase in
                if newPhase == .active {
                    self.checkInbox()
                }
            }
            // Fallback: scenePhase at App level can miss transitions on some iOS versions
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification)
            ) { _ in
                self.checkInbox()
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
            .overlay {
                if self.inboxHandler.isDownloading {
                    DownloadOverlayView {
                        self.inboxHandler.cancelDownload()
                    }
                }
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
            .alert(
                NSLocalizedString("share.download.error.title", comment: ""),
                isPresented: Binding(
                    get: { self.inboxHandler.downloadError != nil },
                    set: { if !$0 { self.inboxHandler.downloadError = nil } }
                )
            ) {
                Button(NSLocalizedString("share.download.error.retry", comment: "")) {
                    self.inboxHandler.downloadError = nil
                    self.checkInbox()
                }
                Button(NSLocalizedString("share.download.error.cancel", comment: ""), role: .cancel) {
                    self.inboxHandler.downloadError = nil
                }
            } message: {
                Text(NSLocalizedString("share.download.error.message", comment: ""))
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

    /// Handles a URL received via onOpenURL
    ///
    /// Distinguishes between:
    /// - `stillmoment://import` — Share Extension trigger, check inbox
    /// - `file://` — "Open with" file association (shared-045)
    private func handleOpenURL(url: URL) {
        if url.scheme == "stillmoment" {
            Logger.guidedMeditation.info("Received URL scheme: \(url.absoluteString)")
            self.checkInbox()
        } else {
            self.handleFileOpen(url: url)
        }
    }

    /// Checks the Share Extension inbox for new entries
    private func checkInbox() {
        Task {
            let result = await self.inboxHandler.processInbox()

            if case let .error(error) = result {
                self.fileOpenErrorMessage = error.localizedDescription
            }
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
            self.cleanUpInboxFile(at: url)
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
        if let url = self.fileOpenHandler.pendingImportURL {
            self.cleanUpInboxFile(at: url)
        }
        self.fileOpenHandler.cancelPendingImport()
    }

    /// Removes a Share Extension inbox file after import completes or is cancelled
    ///
    /// Only deletes files inside the inbox directory — "Open with" files from the
    /// system are not ours to delete.
    private func cleanUpInboxFile(at url: URL) {
        let inboxDir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.stillmoment")?
            .appendingPathComponent("ShareInbox")

        guard let inboxDir, url.path.hasPrefix(inboxDir.path)
        else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - DownloadOverlayView

/// Transparent overlay showing download progress with cancel button
private struct DownloadOverlayView: View {
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text(NSLocalizedString("share.download.loading", comment: ""))
                    .themeFont(.inlineNavigationTitle)

                Button(NSLocalizedString("share.download.cancel", comment: "")) {
                    self.onCancel()
                }
                .buttonStyle(.bordered)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
