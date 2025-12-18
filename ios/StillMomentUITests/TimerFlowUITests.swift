//
//  TimerFlowUITests.swift
//  Still Moment
//
//  Optimized UI Tests - Consolidated from 7 tests to 3 flow-based tests
//  to reduce app launch overhead (ios-005)
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

    // MARK: - Flow Test 1: Basic Timer Flow

    /// Tests app launch, duration selection, and timer start
    /// Consolidates: testAppLaunches, testSelectDurationAndStart, testCircularProgressUpdates
    func testTimerBasicFlow() {
        XCTContext.runActivity(named: "Verify app launches correctly") { _ in
            // App should show main elements
            XCTAssertGreaterThan(self.app.staticTexts.count, 0)

            // Emoji should be visible
            XCTAssertTrue(self.app.staticTexts["🤲"].exists)

            // Start button should exist
            XCTAssertGreaterThan(self.app.buttons.count, 0)
        }

        XCTContext.runActivity(named: "Verify duration picker and start button") { _ in
            // Picker should be visible
            let picker = self.app.pickers["timer.picker.minutes"]
            XCTAssertTrue(picker.exists)

            // Start button should exist and be enabled
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.exists)
            XCTAssertTrue(startButton.isEnabled)
        }

        XCTContext.runActivity(named: "Start timer and verify running state") { _ in
            // Tap start
            self.app.buttons["timer.button.start"].tap()

            // Timer display should appear
            let timerDisplay = self.app.staticTexts["timer.display.time"]
            XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0), "Timer display should appear after starting")

            // Pause button should appear
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0))

            // Reset button should appear
            let resetButton = self.app.buttons["timer.button.reset"]
            XCTAssertTrue(resetButton.waitForExistence(timeout: 2.0))
        }
    }

    // MARK: - Flow Test 2: Timer Controls Flow

    /// Tests pause, resume, reset functionality
    /// Consolidates: testPauseAndResumeTimer, testResetTimer
    func testTimerControlsFlow() {
        // Start timer first
        self.app.buttons["timer.button.start"].tap()

        XCTContext.runActivity(named: "Pause timer") { _ in
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0))
            pauseButton.tap()

            // Resume button should appear
            let resumeButton = self.app.buttons["timer.button.resume"]
            XCTAssertTrue(resumeButton.waitForExistence(timeout: 2.0))

            // State indicator should show paused
            let stateText = self.app.staticTexts["timer.state.text"]
            XCTAssertTrue(stateText.waitForExistence(timeout: 2.0))
        }

        XCTContext.runActivity(named: "Resume timer") { _ in
            let resumeButton = self.app.buttons["timer.button.resume"]
            resumeButton.tap()

            // Pause button should reappear
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0))
        }

        XCTContext.runActivity(named: "Reset timer") { _ in
            let resetButton = self.app.buttons["timer.button.reset"]
            resetButton.tap()

            // Should return to initial state
            let selectDurationLabel = self.app.staticTexts["timer.duration.question"]
            XCTAssertTrue(selectDurationLabel.waitForExistence(timeout: 2.0))

            // Start button should be visible again
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.waitForExistence(timeout: 2.0))
        }
    }

    // MARK: - Flow Test 3: Timer Countdown Verification

    /// Tests that timer actually counts down and validates format
    /// Consolidates: testTimerCountdown, testNavigationBetweenStates
    func testTimerCountdownAndNavigation() {
        XCTContext.runActivity(named: "Verify timer counts down") { _ in
            // Start timer
            self.app.buttons["timer.button.start"].tap()

            // Wait for timer display
            let timerDisplay = self.app.staticTexts["timer.display.time"]
            XCTAssertTrue(timerDisplay.waitForExistence(timeout: 2.0))

            // Get initial time
            let initialTime = timerDisplay.label

            // Wait for time to change using predicate (instead of sleep)
            let predicate = NSPredicate(format: "label != %@", initialTime)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: timerDisplay)
            let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
            XCTAssertEqual(result, .completed, "Timer should count down")

            let laterTime = timerDisplay.label
            XCTAssertNotEqual(initialTime, laterTime, "Timer should have counted down")

            // Verify format is correct (MM:SS)
            do {
                let timeRegex = try NSRegularExpression(pattern: "[0-9]{2}:[0-9]{2}")
                let range = NSRange(location: 0, length: laterTime.utf16.count)
                let match = timeRegex.firstMatch(in: laterTime, range: range)
                XCTAssertNotNil(match, "Timer display should contain time in MM:SS format")
            } catch {
                XCTFail("Failed to create regex: \(error)")
            }
        }

        XCTContext.runActivity(named: "Navigate through all states: Running -> Paused -> Running -> Idle") { _ in
            // Currently in Running state, pause it
            self.app.buttons["timer.button.pause"].tap()
            XCTAssertTrue(self.app.buttons["timer.button.resume"].waitForExistence(timeout: 2.0))
            XCTAssertTrue(self.app.staticTexts["timer.state.text"].waitForExistence(timeout: 2.0))

            // Resume -> Running
            self.app.buttons["timer.button.resume"].tap()
            XCTAssertTrue(self.app.buttons["timer.button.pause"].waitForExistence(timeout: 2.0))

            // Reset -> Idle
            self.app.buttons["timer.button.reset"].tap()
            XCTAssertTrue(self.app.buttons["timer.button.start"].waitForExistence(timeout: 2.0))
            XCTAssertTrue(self.app.staticTexts["timer.duration.question"].waitForExistence(timeout: 2.0))
        }
    }
}
