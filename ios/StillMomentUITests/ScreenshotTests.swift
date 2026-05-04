//
//  ScreenshotTests.swift
//  Still Moment
//
//  Automated screenshot generation for App Store and website.
//  Uses Fastlane Snapshot for multi-language support.
//
//  Run with: cd ios && make screenshots
//

import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
    /// Tab indices matching AppTab order in StillMomentApp.swift.
    /// SwiftUI tabItem ignores accessibilityIdentifier, so index-based access is the stable approach.
    /// shared-084: Library zuerst, danach Timer, dann Settings.
    private enum TabIndex {
        static let library = 0
        static let timer = 1
        static let settings = 2
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        // Screenshot tests require Fastlane/Screenshots target for test fixtures
        // Skip when running via regular CI to avoid failures
        let env = ProcessInfo.processInfo.environment
        let isScreenshotsTarget = env["FASTLANE_SNAPSHOT"] != nil || env["SCREENSHOTS_SCHEME"] != nil
        try XCTSkipUnless(isScreenshotsTarget, "Screenshot tests only run via Fastlane (make screenshots)")

        // Use the Screenshots target bundle ID when running via Fastlane or Screenshots scheme
        let bundleId = "com.stillmoment.StillMoment.screenshots"
        self.app = XCUIApplication(bundleIdentifier: bundleId)

        // Setup Fastlane Snapshot (reads language from cache)
        // waitForAnimations: false - we handle waits explicitly with waitForExistence
        setupSnapshot(self.app, waitForAnimations: false)

        // Disable preparation time for faster screenshots (timer starts immediately)
        self.app.launchArguments += ["-DisablePreparation"]

        // Theme/appearance override comes from Snapfile launch_arguments via setupSnapshot()
        // (e.g., make screenshots THEME=candlelight MODE=dark)

        self.app.launch()

        // Force portrait orientation
        XCUIDevice.shared.orientation = .portrait

        // Wait for app to be fully ready
        let appReady = self.app.wait(for: .runningForeground, timeout: 10)
        XCTAssertTrue(appReady, "App should be running in foreground after launch")
    }

    override func tearDown() {
        self.app = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Navigate to Timer tab
    private func navigateToTimerTab() {
        let timerTab = self.app.tabBars.buttons["Timer"]
        if timerTab.exists, !timerTab.isSelected {
            timerTab.tap()
            _ = self.app.buttons["timer.button.start"].waitForExistence(timeout: 3.0)
        }
    }

    /// Navigate to Library tab
    private func navigateToLibraryTab() {
        let libraryTab = self.app.tabBars.buttons.element(boundBy: TabIndex.library)
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 10.0), "Library tab not found")

        // Always tap the tab to ensure we're on it (even if isSelected, tap again to be sure)
        libraryTab.tap()

        // Verify we're on the Library tab by checking for either add button or empty state
        let addButton = self.app.buttons["library.button.add"]
        let emptyStateButton = self.app.buttons["library.button.import.emptyState"]

        let libraryVisible = addButton.waitForExistence(timeout: 5.0) || emptyStateButton.exists
        XCTAssertTrue(libraryVisible, "Library content not visible after navigation")
    }

    // MARK: - Screenshot Tests

    //
    // Order and naming matches Android (ScreengrabScreenshotTests.kt):
    // 01_TimerIdle, 02_TimerRunning, 03_LibraryList, 04_PlayerView, 05_SettingsView

    /// Screenshot 1: Timer idle state with breath dial (shared-086)
    func testScreenshot01_timerIdle() {
        self.navigateToTimerTab()

        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0), "Start button should exist")

        // Default selectedMinutes ist 10 — Atemkreis zeigt direkt einen schoenen Wert.
        let plusButton = self.app.descendants(matching: .any)["timer.dial.plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 2.0), "Dial should exist")

        snapshot("01_TimerIdle", timeWaitingForIdle: 0)
    }

    /// Screenshot 2: Timer running state (Candlelight Dark theme)
    func testScreenshot02_timerRunning() {
        self.navigateToTimerTab()

        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2.0), "Start button should exist")

        // Default selectedMinutes ist 10 — Atemkreis liefert den gewuenschten Wert direkt.
        let plusButton = self.app.descendants(matching: .any)["timer.dial.plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 2.0), "Dial should exist")

        // Start timer
        startButton.tap()

        // Wait for timer display to appear
        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0), "Timer display should appear")

        snapshot("02_TimerRunning", timeWaitingForIdle: 0)
    }

    /// Screenshot 3: Library with guided meditations (grouped by teacher)
    func testScreenshot03_libraryList() {
        // Navigate to Library tab (Screenshots target has test fixtures seeded)
        self.navigateToLibraryTab()

        // Wait for list to populate with test meditations
        let addButton = self.app.buttons["library.button.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5.0))

        // Wait for first meditation row to appear (ensures list is populated)
        let meditationRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )
        let firstRow = meditationRows.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5.0), "Library should contain test meditations")

        snapshot("03_LibraryList", timeWaitingForIdle: 0)
    }

    /// Screenshot 4: Player with active meditation playback
    func testScreenshot04_playerView() {
        // Navigate to Library tab
        self.navigateToLibraryTab()

        // Tap the first meditation row's play button
        let playImages = self.app.images.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation.'")
        )
        let firstPlayImage = playImages.element(boundBy: 0)
        let emptyState = self.app.buttons["library.button.import.emptyState"]
        XCTAssertTrue(
            firstPlayImage.waitForExistence(timeout: 5.0),
            "No meditation play button found. Empty state visible: \(emptyState.exists)"
        )
        firstPlayImage.tap()

        // Wait for player sheet to appear (auto-start: pause button visible once
        // the main phase is reached — short wait covers the optional pre-roll).
        let pauseButton = self.app.buttons["player.button.playPause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 8.0), "Player did not appear")

        // Auto-Start triggers Zen Mode — kein Tap noetig
        Thread.sleep(forTimeInterval: 0.8)

        snapshot("04_PlayerView", timeWaitingForIdle: 0)
    }

    /// Screenshot 4a: Player Pre-Roll-Phase (Countdown + Hint).
    /// Relauncht ohne `-DisablePreparation`, damit der Vorbereitungs-Countdown
    /// laeuft. Snapshot wird gleich nach dem Tap auf die Meditation gemacht,
    /// solange der Countdown noch sichtbar ist.
    func testScreenshot04a_playerPreRoll() {
        // Re-launch with preparation enabled
        self.app.terminate()
        self.app.launchArguments.removeAll { $0 == "-DisablePreparation" }
        self.app.launch()
        let appReady = self.app.wait(for: .runningForeground, timeout: 10)
        XCTAssertTrue(appReady, "App should be running in foreground after relaunch")

        self.navigateToLibraryTab()

        let playImages = self.app.images.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation.'")
        )
        let firstPlayImage = playImages.element(boundBy: 0)
        XCTAssertTrue(
            firstPlayImage.waitForExistence(timeout: 5.0),
            "No meditation play button found"
        )
        firstPlayImage.tap()

        // Pre-Roll-Countdown muss innerhalb von ~1 s sichtbar sein.
        let countdown = self.app.staticTexts["player.countdown"]
        XCTAssertTrue(
            countdown.waitForExistence(timeout: 3.0),
            "Pre-roll countdown should appear"
        )

        snapshot("04a_PlayerPreRoll", timeWaitingForIdle: 0)
    }

    /// Screenshot 4b: Player paused state (Pause-Glyph als Play, Atem-Glow nutzt
    /// Standby-Werte). Kein eigener Sprachverlauf — nutzt dieselbe Meditation
    /// wie 04, mit einem Pause-Tap dazwischen.
    func testScreenshot04b_playerPaused() {
        self.navigateToLibraryTab()

        let playImages = self.app.images.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation.'")
        )
        let firstPlayImage = playImages.element(boundBy: 0)
        XCTAssertTrue(
            firstPlayImage.waitForExistence(timeout: 5.0),
            "No meditation play button found"
        )
        firstPlayImage.tap()

        let pauseButton = self.app.buttons["player.button.playPause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 8.0), "Player did not appear")

        // Tap pause: Glyph wechselt zu Play, Audio pausiert, Atem laeuft weiter.
        pauseButton.tap()
        Thread.sleep(forTimeInterval: 0.8)

        snapshot("04b_PlayerPaused", timeWaitingForIdle: 0)
    }

    /// Screenshot 5: Interval Gongs editor (deepest configuration screen)
    func testScreenshot05_settingsView() {
        self.navigateToTimerTab()

        // Tap the Interval card — it leads into the most visually rich detail view
        let intervalCard = self.app.buttons["timer.card.interval"]
        XCTAssertTrue(intervalCard.waitForExistence(timeout: 3.0), "Interval card not found")
        intervalCard.tap()

        let intervalToggle = self.app.switches["praxis.editor.toggle.intervalGongs"]
        XCTAssertTrue(intervalToggle.waitForExistence(timeout: 5.0), "Interval editor did not appear")

        // Enable interval gongs for a fuller-looking configuration screen
        if intervalToggle.value as? String == "0" {
            intervalToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            _ = intervalToggle.waitForExistence(timeout: 1.0)
        }

        Thread.sleep(forTimeInterval: 0.3)

        snapshot("05_SettingsView", timeWaitingForIdle: 0)
    }
}
