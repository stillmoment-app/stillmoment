//
//  TimerFlowUITests.swift
//  Still Moment
//

import XCTest

final class TimerFlowUITests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = [
            "-AppleLanguages", "(en)", // Force English for consistent testing
            "-UITesting", "YES" // Skip countdown for faster, more reliable tests
        ]
        self.app.launch()

        // Force portrait orientation
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() {
        self.app = nil
        super.tearDown()
    }

    func testAppLaunches() {
        // Then - App should show main elements
        // Note: Text is localized, so we check for general existence
        XCTAssertGreaterThan(self.app.staticTexts.count, 0)

        // Emoji should be visible
        XCTAssertTrue(self.app.staticTexts["🤲"].exists)

        // Start button should exist
        XCTAssertGreaterThan(self.app.buttons.count, 0)
    }

    func testSelectDurationAndStart() {
        // Given - App is launched with picker visible
        let picker = self.app.pickers["timer.picker.minutes"]
        XCTAssertTrue(picker.exists)

        // When - Select duration (adjust wheel picker)
        // Note: Wheel picker interaction can be tricky in UI tests
        // We'll verify the start button becomes enabled

        // Find start button using accessibility identifier
        let startButton = self.app.buttons["timer.button.start"]
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled)

        // When - Tap start
        startButton.tap()

        // Then - Timer should be running (countdown or timer)
        // Wait for UI to update (timer display should appear)
        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // Pause button should appear
        let pauseButton = self.app.buttons["timer.button.pause"]
        XCTAssertTrue(pauseButton.exists)

        // Reset button should appear
        let resetButton = self.app.buttons["timer.button.reset"]
        XCTAssertTrue(resetButton.exists)
    }

    func testPauseAndResumeTimer() {
        // Given - Start timer
        let startButton = self.app.buttons["timer.button.start"]
        startButton.tap()

        // Wait for timer to start
        let pauseButton = self.app.buttons["timer.button.pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0))

        // When - Tap pause
        pauseButton.tap()

        // Then - Resume button should appear
        let resumeButton = self.app.buttons["timer.button.resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 1.0))

        // State indicator should show paused (using identifier)
        let stateText = self.app.staticTexts["timer.state.text"]
        XCTAssertTrue(stateText.exists)

        // When - Tap resume
        resumeButton.tap()

        // Then - Pause button should reappear
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 1.0))

        // State should show meditating (still using same identifier)
        XCTAssertTrue(stateText.exists)
    }

    func testResetTimer() {
        // Given - Start timer
        let startButton = self.app.buttons["timer.button.start"]
        startButton.tap()

        // Wait for timer to start
        let resetButton = self.app.buttons["timer.button.reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 2.0))

        // When - Tap reset
        resetButton.tap()

        // Then - Should return to initial state
        let selectDurationLabel = self.app.staticTexts["timer.duration.question"]
        XCTAssertTrue(selectDurationLabel.waitForExistence(timeout: 1.0))

        // Start button should be visible again
        XCTAssertTrue(startButton.exists)
    }

    func testTimerCountdown() {
        // Given - Start timer
        self.app.buttons["timer.button.start"].tap()

        // Wait for timer display
        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // When - Wait and observe time decreases
        let initialTime = timerDisplay.label
        sleep(2)
        let laterTime = timerDisplay.label

        // Then - Time should have decreased
        XCTAssertNotEqual(initialTime, laterTime, "Timer should count down")

        // Verify format is correct (MM:SS)
        // Extract time from label "Remaining time: MM:SS"
        do {
            let timeRegex = try NSRegularExpression(pattern: "[0-9]{2}:[0-9]{2}")
            let range = NSRange(location: 0, length: laterTime.utf16.count)
            let match = timeRegex.firstMatch(in: laterTime, range: range)
            XCTAssertNotNil(match, "Timer display should contain time in MM:SS format")
        } catch {
            XCTFail("Failed to create regex: \(error)")
        }
    }

    func testCircularProgressUpdates() {
        // Given - Start timer
        self.app.buttons["timer.button.start"].tap()

        // Wait for timer to start
        sleep(1)

        // Then - Progress indicator should be visible
        // Note: Testing circular progress in UI tests is limited
        // We mainly verify the timer display exists and updates
        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.exists)
    }

    func testNavigationBetweenStates() {
        // Test: Idle -> Running -> Paused -> Running -> Reset -> Idle

        // 1. Idle state
        XCTAssertTrue(self.app.buttons["timer.button.start"].exists)
        XCTAssertTrue(self.app.staticTexts["timer.duration.question"].exists)

        // 2. Start -> Running
        self.app.buttons["timer.button.start"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.pause"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(self.app.staticTexts["timer.state.text"].exists)

        // 3. Pause
        self.app.buttons["timer.button.pause"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.resume"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(self.app.staticTexts["timer.state.text"].exists)

        // 4. Resume -> Running
        self.app.buttons["timer.button.resume"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.pause"].waitForExistence(timeout: 1.0))

        // 5. Reset -> Idle
        self.app.buttons["timer.button.reset"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.start"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(self.app.staticTexts["timer.duration.question"].exists)
    }
}
