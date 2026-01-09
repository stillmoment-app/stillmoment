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

        // Wait for tab content to load
        Thread.sleep(forTimeInterval: 0.5)

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
    func testScreenshot01_TimerIdle() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Ensure picker and start button are visible
        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0))

        let picker = self.app.pickers["timer.picker.minutes"]
        XCTAssertTrue(picker.exists)

        // Select 10 minutes for a nice display
        self.selectDuration(minutes: 10)

        // Small delay for UI to settle
        Thread.sleep(forTimeInterval: 0.5)

        // Take screenshot
        snapshot("01_TimerIdle")
    }

    /// Screenshot 2: Timer running state (~09:55 remaining)
    func testScreenshot02_TimerRunning() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Select 10 minutes
        self.selectDuration(minutes: 10)

        // Start timer
        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0))
        startButton.tap()

        // Wait for timer to be running (countdown is skipped via launch argument)
        let pauseButton = self.app.buttons["timer.button.pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5.0))

        // Wait a few seconds for a realistic time display (~09:55)
        Thread.sleep(forTimeInterval: 5.0)

        // Take screenshot
        snapshot("02_TimerRunning")

        // Reset for next test
        let resetButton = self.app.buttons["timer.button.reset"]
        if resetButton.exists {
            resetButton.tap()
        }
    }

    /// Screenshot 3: Library list with guided meditations
    func testScreenshot03_LibraryList() {
        // Navigate to Library tab (Screenshots target has test fixtures)
        self.navigateToLibraryTab()

        // Wait for list to populate with test meditations
        // The Screenshots target automatically seeds 5 test meditations
        let addButton = self.app.buttons["library.button.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5.0))

        // Small delay for UI to settle
        Thread.sleep(forTimeInterval: 1.0)

        // Take screenshot
        snapshot("03_LibraryList")
    }

    /// Screenshot 4: Player view with meditation
    func testScreenshot04_PlayerView() {
        // Navigate to Library tab
        self.navigateToLibraryTab()

        // Wait longer for list to populate with test fixtures
        Thread.sleep(forTimeInterval: 2.0)

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
                // Debug: Print accessibility hierarchy
                print("DEBUG: App accessibility hierarchy:")
                print(self.app.debugDescription)
                XCTFail("No meditation rows found and no empty state. Check test fixtures seeding.")
            }
            return
        }

        // Wait for player sheet to appear
        let playButton = self.app.buttons["player.button.playPause"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5.0), "Player sheet did not appear")

        // Small delay for UI to settle
        Thread.sleep(forTimeInterval: 0.5)

        // Take screenshot
        snapshot("04_PlayerView")

        // Close player
        let closeButton = self.app.buttons["player.button.close"]
        if closeButton.exists {
            closeButton.tap()
        }
    }

    /// Screenshot 5: Settings view with preparation time and interval gongs enabled
    func testScreenshot05_SettingsView() {
        // Navigate to Timer tab
        self.navigateToTimerTab()

        // Tap the settings button (gear icon)
        let settingsButton = self.app.buttons["timer.button.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3.0), "Settings button not found")
        settingsButton.tap()

        // Wait for settings sheet to fully appear
        Thread.sleep(forTimeInterval: 1.0)

        // Find preparation time toggle
        let preparationToggle = self.app.switches["settings.toggle.preparationTime"]
        XCTAssertTrue(preparationToggle.waitForExistence(timeout: 5.0), "Settings sheet did not appear")

        // Enable preparation time: tap if currently OFF
        if preparationToggle.value as? String == "0" {
            preparationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Find interval gongs toggle - may need to scroll
        let intervalToggle = self.app.switches["settings.toggle.intervalGongs"]
        if !intervalToggle.exists || !intervalToggle.isHittable {
            self.app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
        }
        XCTAssertTrue(intervalToggle.waitForExistence(timeout: 3.0), "Interval gongs toggle not found")

        // Enable interval gongs: tap if currently OFF
        if intervalToggle.value as? String == "0" {
            intervalToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Scroll back to top to show preparation time section
        self.app.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)

        // Take screenshot
        snapshot("05_SettingsView")

        // Close settings
        let doneButton = self.app.buttons["button.done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
}
