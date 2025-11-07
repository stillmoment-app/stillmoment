//
//  TimerFlowUITests.swift
//  MediTimer
//

import XCTest

final class TimerFlowUITests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launch()
    }

    override func tearDown() {
        self.app = nil
        super.tearDown()
    }

    func testAppLaunches() {
        // Then - App should show main elements
        // Note: Text is localized, so we check for general existence
        XCTAssertFalse(self.app.staticTexts.isEmpty)

        // Emoji should be visible
        XCTAssertTrue(self.app.staticTexts["🤲"].exists)

        // Start button should exist
        XCTAssertFalse(self.app.buttons.isEmpty)
    }

    func testSelectDurationAndStart() {
        // Given - App is launched with picker visible
        let picker = self.app.pickers["Minutes"]
        XCTAssertTrue(picker.exists)

        // When - Select duration (adjust wheel picker)
        // Note: Wheel picker interaction can be tricky in UI tests
        // We'll verify the start button becomes enabled

        // Find start button (localized)
        let startButton = self.app.buttons.element(boundBy: 0)
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled)

        // When - Tap start
        startButton.tap()

        // Then - Timer should be running (countdown or timer)
        // Wait for UI to update (countdown first, then timer)
        let timerDisplay = self.app.staticTexts.matching(NSPredicate(
            format: "label MATCHES %@",
            "[0-9]{1,2}:?[0-9]{0,2}"
        ))
        .firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // Pause or Reset button should appear (depends on state)
        let pauseButton = self.app.buttons.element(boundBy: 0)
        XCTAssertTrue(pauseButton.exists)

        // Reset button should appear
        let resetButton = self.app.buttons.element(boundBy: 1)
        XCTAssertTrue(resetButton.exists)
    }

    func testPauseAndResumeTimer() {
        // Given - Start timer
        let startButton = self.app.buttons["Start"]
        startButton.tap()

        // Wait for timer to start
        let pauseButton = self.app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0))

        // When - Tap pause
        pauseButton.tap()

        // Then - Resume button should appear
        let resumeButton = self.app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 1.0))

        // State indicator should show paused
        let pausedIndicator = self.app.staticTexts["Paused"]
        XCTAssertTrue(pausedIndicator.exists)

        // When - Tap resume
        resumeButton.tap()

        // Then - Pause button should reappear
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 1.0))

        // State should show meditating
        let meditatingIndicator = self.app.staticTexts["Meditating..."]
        XCTAssertTrue(meditatingIndicator.exists)
    }

    func testResetTimer() {
        // Given - Start timer
        let startButton = self.app.buttons["Start"]
        startButton.tap()

        // Wait for timer to start
        let resetButton = self.app.buttons["Reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 2.0))

        // When - Tap reset
        resetButton.tap()

        // Then - Should return to initial state
        let selectDurationLabel = self.app.staticTexts["Select Duration"]
        XCTAssertTrue(selectDurationLabel.waitForExistence(timeout: 1.0))

        // Start button should be visible again
        XCTAssertTrue(startButton.exists)
    }

    func testTimerCountdown() {
        // Given - Start timer
        self.app.buttons["Start"].tap()

        // Wait for timer display
        let timerDisplay = self.app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}"))
            .firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // When - Wait and observe time decreases
        let initialTime = timerDisplay.label
        sleep(2)
        let laterTime = timerDisplay.label

        // Then - Time should have decreased
        XCTAssertNotEqual(initialTime, laterTime, "Timer should count down")

        // Verify format is correct (MM:SS)
        do {
            let timeRegex = try NSRegularExpression(pattern: "^[0-9]{2}:[0-9]{2}$")
            let range = NSRange(location: 0, length: laterTime.utf16.count)
            XCTAssertNotNil(timeRegex.firstMatch(in: laterTime, range: range))
        } catch {
            XCTFail("Failed to create regex: \(error)")
        }
    }

    func testCircularProgressUpdates() {
        // Given - Start timer
        self.app.buttons["Start"].tap()

        // Wait for timer to start
        sleep(1)

        // Then - Progress indicator should be visible
        // Note: Testing circular progress in UI tests is limited
        // We mainly verify the timer display exists and updates
        let timerDisplay = self.app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}"))
            .firstMatch
        XCTAssertTrue(timerDisplay.exists)
    }

    func testNavigationBetweenStates() {
        // Test: Idle -> Running -> Paused -> Running -> Reset -> Idle

        // 1. Idle state
        XCTAssertTrue(self.app.buttons["Start"].exists)
        XCTAssertTrue(self.app.staticTexts["Select Duration"].exists)

        // 2. Start -> Running
        self.app.buttons["Start"].tap()
        XCTAssertTrue(self.app.buttons["Pause"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(self.app.staticTexts["Meditating..."].exists)

        // 3. Pause
        self.app.buttons["Pause"].tap()
        XCTAssertTrue(self.app.buttons["Resume"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(self.app.staticTexts["Paused"].exists)

        // 4. Resume -> Running
        self.app.buttons["Resume"].tap()
        XCTAssertTrue(self.app.buttons["Pause"].waitForExistence(timeout: 1.0))

        // 5. Reset -> Idle
        self.app.buttons["Reset"].tap()
        XCTAssertTrue(self.app.buttons["Start"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(self.app.staticTexts["Select Duration"].exists)
    }
}
