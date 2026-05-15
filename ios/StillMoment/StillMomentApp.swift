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

    /// Default tab on first launch (no persisted selection yet).
    /// shared-084: Meditationen-Tab ist Tab 1 — Library = Kernfeature, Timer = Add-on.
    static let defaultTab: AppTab = .library
}

@main
struct StillMomentApp: App {
    // MARK: Lifecycle

    /// Theme manager - owns theme state, injected as @EnvironmentObject
    @StateObject private var themeManager = ThemeManager()

    /// Timer ViewModel — holds the shared AudioService instance
    @StateObject private var timerViewModel: TimerViewModel

    /// Guided meditations list ViewModel — shares the AudioService with timerViewModel
    @StateObject private var guidedListViewModel: GuidedMeditationsListViewModel

    /// File open handler - manages "Open with" and Share Extension imports
    @StateObject private var fileOpenHandler: FileOpenHandler

    /// Inbox handler - processes Share Extension inbox entries
    @StateObject private var inboxHandler: InboxHandler

    /// Persisted tab selection - remembers last used tab across app launches.
    /// First launch (no stored value) lands on AppTab.defaultTab (shared-084).
    @AppStorage("selectedTab")
    private var selectedTab: String = AppTab.defaultTab.rawValue

    /// Navigation path for library tab (enables programmatic navigation)
    @State private var libraryPath = NavigationPath()

    /// Error message from file open handling
    @State private var fileOpenErrorMessage: String?

    /// Scene phase for inbox polling
    @Environment(\.scenePhase)
    private var scenePhase

    init() {
        // Apply launch argument overrides before creating ViewModels
        // (UI tests use -DisablePreparation to configure preparation time behavior)
        if ProcessInfo.processInfo.arguments.contains("-DisablePreparation") {
            PreparationTimeConfigurer.disable()
        }

        // One-time silent cleanup of legacy attunement data (shared-088).
        // Runs before any repository load so persisted state is already clean.
        AttunementCleanupMigration.runIfNeeded()

        let sharedAudioService = AudioService()
        _timerViewModel = StateObject(wrappedValue: TimerViewModel(audioService: sharedAudioService))
        _guidedListViewModel = StateObject(
            wrappedValue: GuidedMeditationsListViewModel(audioService: sharedAudioService)
        )

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
                RootContainerView {
                    TabView(selection: self.$selectedTab) {
                        // Guided Meditations Library Tab — Library = Kernfeature (shared-084).
                        NavigationStack(path: self.$libraryPath) {
                            GuidedMeditationsListView(
                                navigationPath: self.$libraryPath,
                                viewModel: self.guidedListViewModel
                            )
                        }
                        .tabItem {
                            Label("tab.library", systemImage: "waveform")
                        }
                        .tag(AppTab.library.rawValue)
                        .accessibilityIdentifier("tab.library")
                        .accessibilityLabel(Text("tab.library.accessibility"))

                        // Timer Feature Tab — TimerView owns its own NavigationStack
                        // (path-based routing for the five setting detail views).
                        TimerView(viewModel: self.timerViewModel)
                            .tabItem {
                                Label("tab.timer", systemImage: "timer")
                            }
                            .tag(AppTab.timer.rawValue)
                            .accessibilityIdentifier("tab.timer")
                            .accessibilityLabel(Text("tab.timer.accessibility"))

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
            // ios-041: Verlaesst der User den Library-Tab waehrend einer Suche,
            // wird die Eingabe zurueckgesetzt — die Historie bleibt erhalten.
            .onChange(of: self.selectedTab) { newTab in
                if newTab != AppTab.library.rawValue {
                    self.guidedListViewModel.resetSearch()
                }
            }
            // Fallback: scenePhase at App level can miss transitions on some iOS versions
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification)
            ) { _ in
                self.checkInbox()
            }
            .overlay {
                Group {
                    if self.inboxHandler.isDownloading {
                        DownloadOverlayView {
                            self.inboxHandler.cancelDownload()
                        }
                        .transition(.opacity)
                    }
                }
                .animation(
                    .easeInOut(duration: 0.2),
                    value: self.inboxHandler.isDownloading
                )
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
                self.downloadAlertTitleKey,
                isPresented: Binding(
                    get: { self.inboxHandler.downloadError != nil },
                    set: { if !$0 { self.inboxHandler.downloadError = nil } }
                )
            ) {
                self.downloadAlertButtons
            } message: {
                Text(NSLocalizedString(self.downloadAlertMessageKey, comment: ""))
            }
        }
    }

    // MARK: Private

    /// Title-Key fuer den Download-Alert, abhaengig vom konkreten Fehler.
    private var downloadAlertTitleKey: String {
        switch self.inboxHandler.downloadError {
        case .notAnAudioUrl:
            NSLocalizedString("share.download.error.not_audio.title", comment: "")
        default:
            NSLocalizedString("share.download.error.title", comment: "")
        }
    }

    /// Message-Key fuer den Download-Alert, abhaengig vom konkreten Fehler.
    private var downloadAlertMessageKey: String {
        switch self.inboxHandler.downloadError {
        case .notAnAudioUrl:
            "share.download.error.not_audio.message"
        default:
            "share.download.error.message"
        }
    }

    /// Buttons fuer den Download-Alert: Retry nur bei wiederholbaren Fehlern.
    @ViewBuilder private var downloadAlertButtons: some View {
        if self.inboxHandler.downloadError == .notAnAudioUrl {
            Button(NSLocalizedString("common.close", comment: ""), role: .cancel) {
                self.inboxHandler.downloadError = nil
            }
        } else {
            Button(NSLocalizedString("share.download.error.retry", comment: "")) {
                self.inboxHandler.downloadError = nil
                self.checkInbox()
            }
            Button(NSLocalizedString("share.download.error.cancel", comment: ""), role: .cancel) {
                self.inboxHandler.downloadError = nil
            }
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
    ///
    /// Fehler werden vom InboxHandler ueber `downloadError` publiziert — der
    /// Download-Alert ist die Single Source of Truth fuer Share-Inbox-Fehler.
    /// Hier kein zweiter Alert-Pfad noetig (sonst Doppel-Alert).
    private func checkInbox() {
        Task {
            _ = await self.inboxHandler.processInbox()
        }
    }

    /// Handles a file URL received via "Open with" (CFBundleDocumentTypes).
    ///
    /// Imports directly as a meditation. The Library reacts to the published
    /// `importedMeditation` and opens the Edit-Sheet automatically.
    private func handleFileOpen(url: URL) {
        Logger.guidedMeditation.info(
            "Received file open URL",
            metadata: ["file": url.lastPathComponent]
        )

        Task {
            let result = await self.fileOpenHandler.importFile(from: url)
            switch result {
            case .success:
                self.selectedTab = AppTab.library.rawValue
            case let .failure(error):
                self.fileOpenErrorMessage = error.localizedDescription
            }
        }
    }
}
