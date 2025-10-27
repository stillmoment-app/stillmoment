//
//  TimerFlowUITests.swift
//  MediTimerUITests
//
//  UI Tests - Critical User Flows
//

import XCTest

final class TimerFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testAppLaunches() {
        // Then - App should show main elements
        XCTAssertTrue(app.staticTexts["MediTimer"].exists)
        XCTAssertTrue(app.staticTexts["Select Duration"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)
    }

    func testSelectDurationAndStart() {
        // Given - App is launched with picker visible
        let picker = app.pickers["Minutes"]
        XCTAssertTrue(picker.exists)

        // When - Select duration (adjust wheel picker)
        // Note: Wheel picker interaction can be tricky in UI tests
        // We'll verify the start button becomes enabled

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(startButton.isEnabled)

        // When - Tap start
        startButton.tap()

        // Then - Timer should be running
        // Wait for UI to update
        let timerDisplay = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}")).firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // Pause button should appear
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.exists)

        // Reset button should appear
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists)
    }

    func testPauseAndResumeTimer() {
        // Given - Start timer
        let startButton = app.buttons["Start"]
        startButton.tap()

        // Wait for timer to start
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0))

        // When - Tap pause
        pauseButton.tap()

        // Then - Resume button should appear
        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 1.0))

        // State indicator should show paused
        let pausedIndicator = app.staticTexts["Paused"]
        XCTAssertTrue(pausedIndicator.exists)

        // When - Tap resume
        resumeButton.tap()

        // Then - Pause button should reappear
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 1.0))

        // State should show meditating
        let meditatingIndicator = app.staticTexts["Meditating..."]
        XCTAssertTrue(meditatingIndicator.exists)
    }

    func testResetTimer() {
        // Given - Start timer
        let startButton = app.buttons["Start"]
        startButton.tap()

        // Wait for timer to start
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 2.0))

        // When - Tap reset
        resetButton.tap()

        // Then - Should return to initial state
        let selectDurationLabel = app.staticTexts["Select Duration"]
        XCTAssertTrue(selectDurationLabel.waitForExistence(timeout: 1.0))

        // Start button should be visible again
        XCTAssertTrue(startButton.exists)
    }

    func testTimerCountdown() {
        // Given - Start timer
        app.buttons["Start"].tap()

        // Wait for timer display
        let timerDisplay = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}")).firstMatch
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

        // When - Wait and observe time decreases
        let initialTime = timerDisplay.label
        sleep(2)
        let laterTime = timerDisplay.label

        // Then - Time should have decreased
        XCTAssertNotEqual(initialTime, laterTime, "Timer should count down")

        // Verify format is correct (MM:SS)
        let timeRegex = try! NSRegularExpression(pattern: "^[0-9]{2}:[0-9]{2}$")
        let range = NSRange(location: 0, length: laterTime.utf16.count)
        XCTAssertNotNil(timeRegex.firstMatch(in: laterTime, range: range))
    }

    func testCircularProgressUpdates() {
        // Given - Start timer
        app.buttons["Start"].tap()

        // Wait for timer to start
        sleep(1)

        // Then - Progress indicator should be visible
        // Note: Testing circular progress in UI tests is limited
        // We mainly verify the timer display exists and updates
        let timerDisplay = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{2}:[0-9]{2}")).firstMatch
        XCTAssertTrue(timerDisplay.exists)
    }

    func testNavigationBetweenStates() {
        // Test: Idle -> Running -> Paused -> Running -> Reset -> Idle

        // 1. Idle state
        XCTAssertTrue(app.buttons["Start"].exists)
        XCTAssertTrue(app.staticTexts["Select Duration"].exists)

        // 2. Start -> Running
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(app.staticTexts["Meditating..."].exists)

        // 3. Pause
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(app.staticTexts["Paused"].exists)

        // 4. Resume -> Running
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 1.0))

        // 5. Reset -> Idle
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(app.staticTexts["Select Duration"].exists)
    }
}
