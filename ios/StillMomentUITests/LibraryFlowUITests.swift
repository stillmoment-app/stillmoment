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
            "-DisablePreparation" // Skip preparation phase for faster, more reliable tests
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
        self.app.tabBars.buttons["Meditations"]
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

    /// Open the Content Guide sheet via the navigation bar info button.
    /// Waits on a known sheet element (the close button) instead of the sheet container,
    /// since SwiftUI containers do not always surface accessibilityIdentifiers reliably.
    private func openContentGuideSheet() {
        self.navigateToLibraryTab()
        let guideButton = self.app.buttons["library.button.guide"]
        XCTAssertTrue(guideButton.waitForExistence(timeout: 2.0), "Guide button should exist")
        guideButton.tap()
        let closeButton = self.app.buttons["library.guideSheet.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2.0), "Guide sheet should appear")
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

    // MARK: - Flow Test 3: Configuration Editor

    /// Tests navigation to PraxisEditorView via configuration pills
    func testSettingsSheetFlow() {
        // Navigate to Timer first (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Verify configuration pills exist") { _ in
            let configButton = self.app.buttons["timer.button.configuration"]
            XCTAssertTrue(configButton.waitForExistence(timeout: 2.0), "Settings button should exist")
        }

        XCTContext.runActivity(named: "Open PraxisEditorView") { _ in
            let configButton = self.app.buttons["timer.button.configuration"]
            configButton.tap()

            // PraxisEditorView should appear via navigation
            let preparationToggle = self.app.switches["praxis.editor.toggle.preparation"]
            XCTAssertTrue(preparationToggle.waitForExistence(timeout: 3.0), "Praxis editor should appear")
        }

        XCTContext.runActivity(named: "Verify editor UI elements") { _ in
            let preparationToggle = self.app.switches["praxis.editor.toggle.preparation"]
            XCTAssertTrue(preparationToggle.waitForExistence(timeout: 2.0), "Preparation toggle should exist")

            let intervalLink = self.app.buttons["praxis.editor.link.intervalGongs"]
            XCTAssertTrue(intervalLink.waitForExistence(timeout: 2.0), "Interval gongs link should exist")
        }

        XCTContext.runActivity(named: "Toggle preparation time") { _ in
            let preparationToggle = self.app.switches["praxis.editor.toggle.preparation"]
            if preparationToggle.exists {
                XCTAssertTrue(preparationToggle.isEnabled, "Toggle should be enabled")
                preparationToggle.tap()
                XCTAssertTrue(preparationToggle.exists, "Toggle should still exist after tap")
            }
        }

        XCTContext.runActivity(named: "Navigate back to Timer") { _ in
            self.app.navigationBars.buttons.firstMatch.tap()

            // Timer should be visible again
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(
                startButton.waitForExistence(timeout: 2.0),
                "Start button should be visible after navigating back"
            )
        }
    }

    // MARK: - Flow Test 4: Timer Integration with Library

    /// Tests that Timer and Library tabs maintain independent state
    func testTimerAndLibraryIndependentState() {
        // Navigate to Timer first (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Start and end timer") { _ in
            // Start the timer
            let startButton = self.app.buttons["timer.button.start"]
            startButton.tap()

            // Verify timer is running (end button visible)
            let endButton = self.app.buttons["timer.button.end"]
            XCTAssertTrue(endButton.waitForExistence(timeout: 3.0), "Timer should be running with end button")

            // End timer to return to idle
            endButton.tap()

            // Verify we're back to idle state
            let startButtonAgain = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButtonAgain.waitForExistence(timeout: 2.0), "Should return to idle state")
        }

        XCTContext.runActivity(named: "Switch to Library tab") { _ in
            self.libraryTab().tap()

            // Library should show its content
            let importButton = self.app.buttons["library.button.import.emptyState"]
            let addButton = self.app.buttons["library.button.add"]
            XCTAssertTrue(
                importButton.waitForExistence(timeout: 2.0) || addButton.waitForExistence(timeout: 1.0),
                "Library content should be visible"
            )
        }

        XCTContext.runActivity(named: "Return to Timer and verify idle state preserved") { _ in
            self.timerTab().tap()

            // Timer should still be in idle state with start button visible
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.waitForExistence(timeout: 2.0), "Timer should be in idle state")

            // Duration picker should still be visible
            let picker = self.app.pickers["timer.picker.minutes"]
            XCTAssertTrue(picker.exists, "Duration picker should be visible")
        }
    }

    // MARK: - Flow Test 5: Content Guide Import Banners (shared-039b)

    /// Tests that the Content Guide sheet shows both import banners above the source list.
    func testGuideSheetShowsImportBanners() {
        self.openContentGuideSheet()

        let browserBanner = self.app.buttons["library.guideSheet.banner.browser"]
        let filesBanner = self.app.buttons["library.guideSheet.banner.files"]

        XCTAssertTrue(browserBanner.waitForExistence(timeout: 2.0), "Browser banner should be visible")
        XCTAssertTrue(filesBanner.waitForExistence(timeout: 2.0), "Files banner should be visible")
    }

    /// Tests that tapping the browser banner pushes the browser how-to view, and the
    /// back button returns to the source list.
    func testBrowserBannerPushesHowtoAndBackReturns() {
        self.openContentGuideSheet()

        let browserBanner = self.app.buttons["library.guideSheet.banner.browser"]
        XCTAssertTrue(browserBanner.waitForExistence(timeout: 2.0), "Browser banner should be visible")
        browserBanner.tap()

        let howtoTitle = self.app.staticTexts["library.guideSheet.howto.browser.title"]
        XCTAssertTrue(howtoTitle.waitForExistence(timeout: 2.0), "Browser how-to should be pushed")

        // Native back button is the leading button in the navigation bar.
        let backButton = self.app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 2.0), "Back button should exist")
        backButton.tap()

        XCTAssertTrue(
            browserBanner.waitForExistence(timeout: 2.0),
            "Browser banner should be visible again after back"
        )
    }

    /// Tests that tapping the files banner pushes the files how-to view, and the
    /// back button returns to the source list.
    func testFilesBannerPushesHowtoAndBackReturns() {
        self.openContentGuideSheet()

        let filesBanner = self.app.buttons["library.guideSheet.banner.files"]
        XCTAssertTrue(filesBanner.waitForExistence(timeout: 2.0), "Files banner should be visible")
        filesBanner.tap()

        let howtoTitle = self.app.staticTexts["library.guideSheet.howto.files.title"]
        XCTAssertTrue(howtoTitle.waitForExistence(timeout: 2.0), "Files how-to should be pushed")

        let backButton = self.app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 2.0), "Back button should exist")
        backButton.tap()

        XCTAssertTrue(
            filesBanner.waitForExistence(timeout: 2.0),
            "Files banner should be visible again after back"
        )
    }
}
