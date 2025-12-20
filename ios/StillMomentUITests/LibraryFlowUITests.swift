//
//  LibraryFlowUITests.swift
//  Still Moment
//
//  UI Tests for Guided Meditations Library and Player features (ios-012)
//

import XCTest

final class LibraryFlowUITests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = [
            "-AppleLanguages", "(en)", // Force English for consistent testing
            "-CountdownDuration", "0" // Skip countdown for faster, more reliable tests
        ]

        self.app.launch()

        // Force portrait orientation
        XCUIDevice.shared.orientation = .portrait

        // Wait for app to be fully ready after launch
        let appReady = self.app.wait(for: .runningForeground, timeout: 5)
        XCTAssertTrue(appReady, "App should be running in foreground after launch")
    }

    override func tearDown() {
        self.app = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Find tab button by localized label (TabBar buttons use labels, not identifiers)
    private func timerTab() -> XCUIElement {
        self.app.tabBars.buttons["Timer"]
    }

    private func libraryTab() -> XCUIElement {
        self.app.tabBars.buttons["Library"]
    }

    /// Ensure we're on the Timer tab (app remembers last tab via @AppStorage)
    private func navigateToTimerTab() {
        let timerTab = self.timerTab()
        if timerTab.exists, !timerTab.isSelected {
            timerTab.tap()
            _ = self.app.buttons["timer.button.start"].waitForExistence(timeout: 2.0)
        }
    }

    /// Ensure we're on the Library tab
    private func navigateToLibraryTab() {
        let libraryTab = self.libraryTab()
        if libraryTab.exists, !libraryTab.isSelected {
            libraryTab.tap()
        }
        // Wait for Library content to load
        let importButton = self.app.buttons["library.button.import.emptyState"]
        let addButton = self.app.buttons["library.button.add"]
        _ = importButton.waitForExistence(timeout: 2.0) || addButton.waitForExistence(timeout: 1.0)
    }

    // MARK: - Flow Test 1: Tab Navigation

    /// Tests tab navigation between Timer and Library
    func testTabNavigationFlow() {
        // Navigate to Timer first (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Verify Timer tab content") { _ in
            // Timer tab should be selected
            let timerTab = self.timerTab()
            XCTAssertTrue(timerTab.exists, "Timer tab should exist")
            XCTAssertTrue(timerTab.isSelected, "Timer tab should be selected")

            // Start button should be visible (Timer view)
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.exists, "Start button should be visible on Timer tab")
        }

        XCTContext.runActivity(named: "Navigate to Library tab") { _ in
            let libraryTab = self.libraryTab()
            XCTAssertTrue(libraryTab.exists, "Library tab should exist")
            libraryTab.tap()

            // Library tab should be selected
            XCTAssertTrue(libraryTab.waitForExistence(timeout: 2.0))

            // Import button should be visible (Library view)
            let importButton = self.app.buttons["library.button.import.emptyState"]
            let addButton = self.app.buttons["library.button.add"]
            XCTAssertTrue(
                importButton.waitForExistence(timeout: 2.0) || addButton.waitForExistence(timeout: 2.0),
                "Import button should be visible on Library tab"
            )
        }

        XCTContext.runActivity(named: "Navigate back to Timer tab") { _ in
            self.timerTab().tap()

            // Start button should be visible again
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(
                startButton.waitForExistence(timeout: 2.0),
                "Start button should be visible after returning to Timer"
            )
        }
    }

    // MARK: - Flow Test 2: Library Empty State

    /// Tests Library empty state UI elements
    func testLibraryEmptyStateFlow() {
        // Navigate to Library tab
        self.navigateToLibraryTab()

        XCTContext.runActivity(named: "Verify Library content") { _ in
            // Wait for Library view to load
            let importButton = self.app.buttons["library.button.import.emptyState"]
            let addButton = self.app.buttons["library.button.add"]

            // Either empty state or list with add button should be visible
            let hasImportButton = importButton.waitForExistence(timeout: 3.0)
            let hasAddButton = addButton.waitForExistence(timeout: 1.0)

            XCTAssertTrue(hasImportButton || hasAddButton, "Library should show import or add button")
        }

        XCTContext.runActivity(named: "Verify import button is tappable") { _ in
            // Check if empty state is shown
            let importButton = self.app.buttons["library.button.import.emptyState"]
            if importButton.exists {
                XCTAssertTrue(importButton.isEnabled, "Import button should be enabled")
                // Note: Actually tapping would open file picker, which we can't control in UI tests
            }
        }
    }

    // MARK: - Flow Test 3: Settings Sheet

    /// Tests Settings sheet flow from Timer view
    func testSettingsSheetFlow() {
        // Navigate to Timer first (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Verify Settings button exists") { _ in
            let settingsButton = self.app.buttons["timer.button.settings"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 2.0), "Settings button should exist")
        }

        XCTContext.runActivity(named: "Open Settings sheet") { _ in
            let settingsButton = self.app.buttons["timer.button.settings"]
            settingsButton.tap()

            // Settings sheet should appear - look for Done button
            let doneButton = self.app.buttons["button.done"]
            XCTAssertTrue(doneButton.waitForExistence(timeout: 3.0), "Done button should appear in Settings")
        }

        XCTContext.runActivity(named: "Verify Settings UI elements") { _ in
            // Background sound picker should exist
            // Note: Picker accessibility is tricky, we check for the toggle instead
            let intervalToggle = self.app.switches["settings.toggle.intervalGongs"]
            XCTAssertTrue(intervalToggle.waitForExistence(timeout: 2.0), "Interval gongs toggle should exist")
        }

        XCTContext.runActivity(named: "Toggle interval gongs") { _ in
            let intervalToggle = self.app.switches["settings.toggle.intervalGongs"]
            if intervalToggle.exists {
                // Toggle should be enabled and tappable
                XCTAssertTrue(intervalToggle.isEnabled, "Toggle should be enabled")
                intervalToggle.tap()

                // Toggle should still exist after tap (basic interaction test)
                XCTAssertTrue(intervalToggle.exists, "Toggle should still exist after tap")
            }
        }

        XCTContext.runActivity(named: "Close Settings sheet") { _ in
            let doneButton = self.app.buttons["button.done"]
            doneButton.tap()

            // Settings should close, start button should be visible
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(
                startButton.waitForExistence(timeout: 2.0),
                "Start button should be visible after closing Settings"
            )
        }
    }

    // MARK: - Flow Test 4: Timer Integration with Library

    /// Tests that Timer and Library tabs maintain independent state
    func testTimerAndLibraryIndependentState() {
        // Navigate to Timer first (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Start timer on Timer tab") { _ in
            // Start the timer
            let startButton = self.app.buttons["timer.button.start"]
            startButton.tap()

            // Verify timer is running (with countdown=0, pause button should appear quickly)
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0), "Timer should be running")
        }

        XCTContext.runActivity(named: "Switch to Library tab while timer runs") { _ in
            self.libraryTab().tap()

            // Library should show its content
            let importButton = self.app.buttons["library.button.import.emptyState"]
            let addButton = self.app.buttons["library.button.add"]
            XCTAssertTrue(
                importButton.waitForExistence(timeout: 2.0) || addButton.waitForExistence(timeout: 1.0),
                "Library content should be visible"
            )
        }

        XCTContext.runActivity(named: "Return to Timer and verify state preserved") { _ in
            self.timerTab().tap()

            // Timer should still be running (pause button visible)
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0), "Timer should still be running")

            // Reset for cleanup
            let resetButton = self.app.buttons["timer.button.reset"]
            if resetButton.exists {
                resetButton.tap()
            }
        }
    }
}
