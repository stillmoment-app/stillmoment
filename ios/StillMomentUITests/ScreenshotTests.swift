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

        // The empty-library screenshot needs a cleared library; a later launch without
        // the flag re-seeds via seedIfNeeded, so order between tests does not matter.
        if self.name.contains("emptyLibrary") {
            self.app.launchArguments += ["-EmptyLibrary"]
        }

        // Appearance override comes from Snapfile launch_arguments via setupSnapshot()
        // (e.g., make screenshots MODE=dark)

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

    /// Navigate to App Settings tab (appearance + language + attributions)
    private func navigateToSettingsTab() {
        let settingsTab = self.app.tabBars.buttons.element(boundBy: TabIndex.settings)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10.0), "Settings tab not found")
        settingsTab.tap()

        let attributionsRow = self.app.buttons["app.settings.row.soundAttributions"]
        XCTAssertTrue(attributionsRow.waitForExistence(timeout: 5.0), "Settings content not visible")
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
        let dial = self.app.descendants(matching: .any)["timer.dial"]
        XCTAssertTrue(dial.waitForExistence(timeout: 2.0), "Dial should exist")

        snapshot("01_TimerIdle", timeWaitingForIdle: 0)
    }

    /// Screenshot 2: Timer running state with visible moon-phase progress (ios-047).
    ///
    /// Uses `-DurationMinutes 1` to shorten the session so ~25 % progress is reached
    /// within ~15 s of wall-clock time. Waits for the display to count down into the
    /// 00:43 – 00:45 range (shadow visibly moved, halo dezent, not yet half-moon).
    func testScreenshot02_timerRunning() {
        // ios-047: relaunch with a short session so the moon-phase visualisation has
        // moved noticeably by the time the snapshot is taken.
        self.app.terminate()
        self.app.launchArguments += ["-DurationMinutes", "1"]
        self.app.launch()

        self.navigateToTimerTab()

        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2.0), "Start button should exist")

        let dial = self.app.descendants(matching: .any)["timer.dial"]
        XCTAssertTrue(dial.waitForExistence(timeout: 2.0), "Dial should exist")

        startButton.tap()

        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0), "Timer display should appear")

        // Wait until ~25 % of the session has elapsed — accessibilityValue starts with
        // the remaining seconds ("45 Sekunden verbleibend" / "45 seconds remaining"),
        // so BEGINSWITH matches independent of language. 43-45 s remaining = 25-28 %
        // progress: shadow visibly moved, no half-moon yet.
        let progressReached = NSPredicate(
            format: "value BEGINSWITH '45' OR value BEGINSWITH '44' OR value BEGINSWITH '43'"
        )
        let progressExpectation = XCTNSPredicateExpectation(
            predicate: progressReached,
            object: timerDisplay
        )
        let result = XCTWaiter().wait(for: [progressExpectation], timeout: 30.0)
        XCTAssertEqual(
            result,
            .completed,
            "Timer did not reach ~25% progress within 30s (last value: \(timerDisplay.value ?? "nil"))"
        )

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

        // Open the player via the play button. It is an image that carries the row's
        // identifier (library.row.meditation.<id>); a tap navigates into the player,
        // a long press would start an in-list preview instead.
        let playButtons = self.app.images.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )
        let firstPlayButton = playButtons.firstMatch
        let emptyState = self.app.buttons["library.button.import.emptyState"]
        XCTAssertTrue(
            firstPlayButton.waitForExistence(timeout: 5.0),
            "No meditation play button found. Empty state visible: \(emptyState.exists)"
        )
        firstPlayButton.tap()

        // Auto-start begins playback; the remaining-time line confirms the player content.
        let remainingTime = self.app.staticTexts["player.text.remainingTime"]
        XCTAssertTrue(remainingTime.waitForExistence(timeout: 12.0), "Player content did not appear")

        // Seek forward so the player shows a meditation in progress rather than at the start.
        // The full-track mini overview ("Gesamtfortschritt") is an absolute seek: tapping at a
        // fraction of its width jumps there. A single tap at ~1/3 is far more reliable than
        // dragging the fine-grained waveform window (synthesized drags barely register there).
        let miniOverview = self.app.otherElements["player.miniOverview"]
        if miniOverview.waitForExistence(timeout: 3.0) {
            miniOverview.coordinate(withNormalizedOffset: CGVector(dx: 0.33, dy: 0.5)).tap()
        }

        Thread.sleep(forTimeInterval: 0.8)

        snapshot("04_PlayerView", timeWaitingForIdle: 0)
    }

    /// Screenshot 6: Edit sheet — same layout as the Import sheet, used to showcase
    /// how users curate a library entry (teacher + name + file footer).
    func testScreenshot06_editSheet() {
        self.navigateToLibraryTab()

        let meditationRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )
        let firstRow = meditationRows.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5.0), "Library should contain test meditations")

        firstRow.swipeLeft()

        let editButton = self.app.buttons["library.row.swipe.edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3.0), "Edit swipe action not visible")
        editButton.tap()

        // Edit mode does not auto-focus — keyboard stays down, both fields visible.
        let teacherField = self.app.textFields["editSheet.field.teacher"]
        XCTAssertTrue(teacherField.waitForExistence(timeout: 3.0), "Edit sheet did not appear")

        // Let the sheet present-animation settle before capturing.
        Thread.sleep(forTimeInterval: 0.4)

        snapshot("06_EditSheet", timeWaitingForIdle: 0)
    }

    /// Screenshot 5: Interval Gongs editor (deepest configuration screen)
    func testScreenshot05_settingsView() {
        self.navigateToTimerTab()

        // Tap the Interval row — it leads into the most visually rich detail view
        let intervalRow = self.app.buttons["timer.row.interval"]
        XCTAssertTrue(intervalRow.waitForExistence(timeout: 3.0), "Interval row not found")
        intervalRow.tap()

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

    /// Screenshot 7: Preparation time selection (timer detail screen)
    func testScreenshot07_preparation() {
        self.navigateToTimerTab()

        let preparationRow = self.app.buttons["timer.row.preparation"]
        XCTAssertTrue(preparationRow.waitForExistence(timeout: 3.0), "Preparation row not found")
        preparationRow.tap()

        let preparationToggle = self.app.descendants(matching: .any)["praxis.preparation.toggle"]
        XCTAssertTrue(preparationToggle.waitForExistence(timeout: 5.0), "Preparation screen did not appear")

        Thread.sleep(forTimeInterval: 0.3)

        snapshot("07_Preparation", timeWaitingForIdle: 0)
    }

    /// Screenshot 8: Gong selection — redesigned card layout with waveform (shared-115)
    func testScreenshot08_gongSelection() {
        self.navigateToTimerTab()

        let gongRow = self.app.buttons["timer.row.gong"]
        XCTAssertTrue(gongRow.waitForExistence(timeout: 3.0), "Gong row not found")
        gongRow.tap()

        // The sound rows (praxis.gong.<id>) always render — robust anchor for "screen appeared".
        let gongSoundRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'praxis.gong.'")
        )
        XCTAssertTrue(gongSoundRows.firstMatch.waitForExistence(timeout: 5.0), "Gong selection did not appear")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("08_GongSelection", timeWaitingForIdle: 0)
    }

    /// Screenshot 9: Soundscape / background sound selection (timer detail screen)
    func testScreenshot09_soundscape() {
        self.navigateToTimerTab()

        let backgroundRow = self.app.buttons["timer.row.background"]
        XCTAssertTrue(backgroundRow.waitForExistence(timeout: 3.0), "Background row not found")
        backgroundRow.tap()

        // The sound rows (praxis.background.<id>) always render — robust anchor for "screen appeared".
        let soundRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'praxis.background.'")
        )
        XCTAssertTrue(soundRows.firstMatch.waitForExistence(timeout: 5.0), "Soundscape selection did not appear")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("09_Soundscape", timeWaitingForIdle: 0)
    }

    /// Screenshot 10: App settings (appearance + language)
    func testScreenshot10_appSettings() {
        self.navigateToSettingsTab()

        Thread.sleep(forTimeInterval: 0.3)

        snapshot("10_AppSettings", timeWaitingForIdle: 0)
    }

    /// Screenshot 11: Sound attributions (Pixabay credits, pushed from settings)
    func testScreenshot11_soundAttributions() {
        self.navigateToSettingsTab()

        let attributionsRow = self.app.buttons["app.settings.row.soundAttributions"]
        XCTAssertTrue(attributionsRow.waitForExistence(timeout: 3.0), "Attributions row not found")
        attributionsRow.tap()

        // Pushed screen — the navigation back button confirms we left the list.
        let backButton = self.app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5.0), "Attributions screen did not appear")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("11_SoundAttributions", timeWaitingForIdle: 0)
    }

    /// Screenshot 12: Library search with results
    func testScreenshot12_librarySearch() {
        self.navigateToLibraryTab()

        let searchField = self.app.textFields["library.search.field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "Search field not found")
        searchField.tap()
        searchField.typeText("b")

        let resultRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.search.row'")
        )
        XCTAssertTrue(resultRows.firstMatch.waitForExistence(timeout: 5.0), "No search results appeared")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("12_LibrarySearch", timeWaitingForIdle: 0)
    }

    /// Screenshot 13: Import guide sheet (how to add own MP3s)
    func testScreenshot13_importGuide() {
        self.navigateToLibraryTab()

        let guideButton = self.app.buttons["library.button.guide"]
        XCTAssertTrue(guideButton.waitForExistence(timeout: 5.0), "Guide button not found")
        guideButton.tap()

        let browserBanner = self.app.buttons["library.guideSheet.banner.browser"]
        XCTAssertTrue(browserBanner.waitForExistence(timeout: 5.0), "Guide sheet did not appear")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("13_ImportGuide", timeWaitingForIdle: 0)
    }

    /// Screenshot 14: Trim editor (playback range), opened from the edit sheet
    func testScreenshot14_trimEditor() {
        self.navigateToLibraryTab()

        let meditationRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )
        let firstRow = meditationRows.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5.0), "Library should contain test meditations")

        firstRow.swipeLeft()

        let editButton = self.app.buttons["library.row.swipe.edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3.0), "Edit swipe action not visible")
        editButton.tap()

        let playbackCard = self.app.buttons["editSheet.card.playbackRange"]
        XCTAssertTrue(playbackCard.waitForExistence(timeout: 5.0), "Playback range card not found")
        playbackCard.tap()

        let trimSheet = self.app.descendants(matching: .any)["trimEditor.sheet"]
        XCTAssertTrue(trimSheet.waitForExistence(timeout: 5.0), "Trim editor did not appear")

        // Let the waveform render before capturing.
        Thread.sleep(forTimeInterval: 1.0)

        snapshot("14_TrimEditor", timeWaitingForIdle: 0)
    }

    /// Screenshot 15: Completion screen (Danke lotus mandala) after a session ends.
    ///
    /// Uses `-DurationMinutes 1` plus disabled preparation so the timer finishes
    /// within ~60 s and the completion view appears.
    func testScreenshot15_completion() {
        self.app.terminate()
        self.app.launchArguments += ["-DurationMinutes", "1"]
        self.app.launch()

        self.navigateToTimerTab()

        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0), "Start button should exist")
        startButton.tap()

        // Wait for the natural end — the done button only exists on the completion screen.
        let doneButton = self.app.buttons["completion.button.done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 90.0), "Completion screen did not appear")

        Thread.sleep(forTimeInterval: 0.6)

        snapshot("15_Completion", timeWaitingForIdle: 0)
    }

    /// Screenshot 16: Empty library (first launch, before any import).
    ///
    /// The library is cleared via the `-EmptyLibrary` launch argument (set in setUp for
    /// this test); a later launch without the flag re-seeds, so test order does not matter.
    func testScreenshot16_emptyLibrary() {
        self.navigateToLibraryTab()

        let emptyImport = self.app.buttons["library.button.import.emptyState"]
        XCTAssertTrue(emptyImport.waitForExistence(timeout: 5.0), "Empty library state did not appear")

        Thread.sleep(forTimeInterval: 0.4)

        snapshot("16_EmptyLibrary", timeWaitingForIdle: 0)
    }
}
