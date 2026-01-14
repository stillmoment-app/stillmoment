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
        setupSnapshot(self.app)

        // Skip 15-second countdown for faster screenshots
        self.app.launchArguments += ["-CountdownDuration", "0"]

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
        // XCUITest finds tab buttons by their localized label text, not accessibility identifier
        // "Library" (EN) or "Bibliothek" (DE)
        var libraryTab = self.app.tabBars.buttons["Library"]
        if !libraryTab.exists {
            libraryTab = self.app.tabBars.buttons["Bibliothek"]
        }
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 10.0), "Library tab not found")

        // Always tap the tab to ensure we're on it (even if isSelected, tap again to be sure)
        libraryTab.tap()

        // Verify we're on the Library tab by checking for either add button or empty state
        let addButton = self.app.descendants(matching: .any)["library.button.add"]
        let emptyStateButton = self.app.buttons["library.button.import.emptyState"]

        let libraryVisible = addButton.waitForExistence(timeout: 5.0) || emptyStateButton.exists
        XCTAssertTrue(libraryVisible, "Library content not visible after navigation")
    }

    /// Select duration in picker
    private func selectDuration(minutes: Int) {
        let picker = self.app.pickers["timer.picker.minutes"]
        guard picker.exists else {
            return
        }

        // Swipe to desired value (picker shows "X min" format)
        let pickerWheel = picker.pickerWheels.firstMatch
        pickerWheel.adjust(toPickerWheelValue: "\(minutes) min")
    }

    // MARK: - Screenshot Tests

    /// Screenshot 1: Timer idle state with duration picker
    func testScreenshot01_timerIdle() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Ensure picker and start button are visible
        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0))

        let picker = self.app.pickers["timer.picker.minutes"]
        XCTAssertTrue(picker.exists)

        // Select 10 minutes for a nice display
        self.selectDuration(minutes: 10)

        // Wait for picker animation to complete
        _ = startButton.waitForExistence(timeout: 1.0)

        // Take screenshot
        snapshot("01_TimerIdle")
    }

    /// Screenshot 2: Timer running state (~00:57 remaining)
    func testScreenshot02_timerRunning() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Select 1 minute for faster screenshot (less waiting)
        self.selectDuration(minutes: 1)

        // Start timer
        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0))
        startButton.tap()

        // Wait for timer to be running (countdown is skipped via launch argument)
        let pauseButton = self.app.buttons["timer.button.pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5.0))

        // Wait ~3 seconds for a nice time display (00:57)
        // Using explicit wait instead of Thread.sleep for better reliability
        let timerLabel = self.app.staticTexts.matching(
            NSPredicate(format: "label MATCHES '00:5[0-9]'")
        ).firstMatch
        _ = timerLabel.waitForExistence(timeout: 10.0)

        // Take screenshot
        snapshot("02_TimerRunning")
    }

    /// Screenshot 3: Library list with guided meditations
    func testScreenshot03_libraryList() {
        // Navigate to Library tab (Screenshots target has test fixtures)
        self.navigateToLibraryTab()

        // Wait for list to populate with test meditations
        // The Screenshots target automatically seeds 5 test meditations
        let addButton = self.app.buttons["library.button.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5.0))

        // Wait for first meditation row to appear (ensures list is populated)
        let meditationRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )
        _ = meditationRows.firstMatch.waitForExistence(timeout: 5.0)

        // Take screenshot
        snapshot("03_LibraryList")
    }

    /// Screenshot 4: Player view with meditation
    func testScreenshot04_playerView() {
        // Navigate to Library tab
        self.navigateToLibraryTab()

        // Find and tap the first meditation row
        // Test fixtures include "Mindful Breathing" by Sarah Kornfield
        // Note: The rows are Buttons in SwiftUI, not Cells, so we search for any element
        let meditationRows = self.app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
        )

        // Wait for meditation rows to appear (test fixtures should be loaded)
        let firstMeditationRow = meditationRows.element(boundBy: 0)
        let hasMeditations = firstMeditationRow.waitForExistence(timeout: 5.0)

        if hasMeditations {
            // Tap the meditation row to open player
            firstMeditationRow.tap()
        } else {
            // No meditations found - check if empty state is visible
            let emptyStateButton = self.app.buttons["library.button.import.emptyState"]
            if emptyStateButton.exists {
                XCTFail("Library is empty - test fixtures not loaded. Empty state visible.")
            } else {
                XCTFail("No meditation rows found and no empty state. Check test fixtures seeding.")
            }
            return
        }

        // Wait for player sheet to appear with all elements loaded
        let playButton = self.app.buttons["player.button.playPause"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5.0), "Player sheet did not appear")

        // Wait for meditation title to be visible (ensures sheet is fully rendered)
        let titleLabel = self.app.staticTexts["Mindful Breathing"]
        _ = titleLabel.waitForExistence(timeout: 3.0)

        // Take screenshot
        snapshot("04_PlayerView")
    }

    /// Screenshot 5: Settings view with preparation time and interval gongs enabled
    func testScreenshot05_settingsView() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Tap the settings button (gear icon)
        let settingsButton = self.app.buttons["timer.button.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3.0), "Settings button not found")
        settingsButton.tap()

        // Find preparation time toggle (wait for sheet to appear)
        let preparationToggle = self.app.switches["settings.toggle.preparationTime"]
        XCTAssertTrue(preparationToggle.waitForExistence(timeout: 5.0), "Settings sheet did not appear")

        // Enable preparation time: tap if currently OFF
        if preparationToggle.value as? String == "0" {
            preparationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            // Wait for toggle animation
            _ = preparationToggle.waitForExistence(timeout: 1.0)
        }

        // Find interval gongs toggle - may need to scroll
        let intervalToggle = self.app.switches["settings.toggle.intervalGongs"]
        if !intervalToggle.exists || !intervalToggle.isHittable {
            self.app.swipeUp()
            _ = intervalToggle.waitForExistence(timeout: 2.0)
        }
        XCTAssertTrue(intervalToggle.waitForExistence(timeout: 3.0), "Interval gongs toggle not found")

        // Enable interval gongs: tap if currently OFF
        if intervalToggle.value as? String == "0" {
            intervalToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            // Wait for toggle animation
            _ = intervalToggle.waitForExistence(timeout: 1.0)
        }

        // Scroll back to top to show preparation time section
        self.app.swipeDown()
        // Wait for scroll to complete
        _ = preparationToggle.waitForExistence(timeout: 2.0)

        // Take screenshot
        snapshot("05_SettingsView")
    }
}
