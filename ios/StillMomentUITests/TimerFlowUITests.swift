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

    /// Ensure we're on the Timer tab (app remembers last tab via @AppStorage)
    private func navigateToTimerTab() {
        let timerTab = self.app.tabBars.buttons["Timer"]
        if timerTab.exists, !timerTab.isSelected {
            timerTab.tap()
            _ = self.app.buttons["timer.button.start"].waitForExistence(timeout: 2.0)
        }
    }

    // MARK: - Flow Test 1: Basic Timer Flow

    /// Tests app launch, duration selection, and timer start
    /// Consolidates: testAppLaunches, testSelectDurationAndStart, testCircularProgressUpdates
    func testTimerBasicFlow() {
        // Navigate to Timer tab (app may remember last tab)
        self.navigateToTimerTab()

        XCTContext.runActivity(named: "Verify app launches correctly") { _ in
            // App should show main elements
            XCTAssertGreaterThan(self.app.staticTexts.count, 0)

            // Start button should exist
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.exists, "Start button should be visible")
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

            // Timer display should appear (countdown or time)
            let timerDisplay = self.app.staticTexts["timer.display.time"]
            XCTAssertTrue(
                timerDisplay.waitForExistence(timeout: 3.0),
                "Timer display should appear after starting"
            )

            // Pause button should appear
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0), "Pause button should appear")

            // End button should appear in toolbar
            let endButton = self.app.buttons["timer.button.end"]
            XCTAssertTrue(endButton.waitForExistence(timeout: 2.0), "End button should appear in toolbar")
        }
    }

    // MARK: - Flow Test 2: Timer Controls Flow

    /// Tests pause, resume, end functionality
    /// Consolidates: testPauseAndResumeTimer, testResetTimer
    func testTimerControlsFlow() {
        // Navigate to Timer tab (app may remember last tab)
        self.navigateToTimerTab()

        // Start timer first
        self.app.buttons["timer.button.start"].tap()

        XCTContext.runActivity(named: "Pause timer") { _ in
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0), "Pause button should exist")
            pauseButton.tap()

            // Resume button should appear
            let resumeButton = self.app.buttons["timer.button.resume"]
            XCTAssertTrue(resumeButton.waitForExistence(timeout: 2.0), "Resume button should appear after pause")

            // State indicator should show paused
            let stateText = self.app.staticTexts["timer.state.text"]
            XCTAssertTrue(stateText.waitForExistence(timeout: 2.0), "State text should be visible")
        }

        XCTContext.runActivity(named: "Resume timer") { _ in
            let resumeButton = self.app.buttons["timer.button.resume"]
            resumeButton.tap()

            // Pause button should reappear
            let pauseButton = self.app.buttons["timer.button.pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2.0), "Pause button should reappear after resume")
        }

        XCTContext.runActivity(named: "End timer to return to selection") { _ in
            // End button resets timer
            let endButton = self.app.buttons["timer.button.end"]
            XCTAssertTrue(endButton.exists, "End button should exist")
            endButton.tap()

            // Should return to initial state
            let selectDurationLabel = self.app.staticTexts["timer.duration.question"]
            XCTAssertTrue(selectDurationLabel.waitForExistence(timeout: 2.0), "Duration question should reappear")

            // Start button should be visible again
            let startButton = self.app.buttons["timer.button.start"]
            XCTAssertTrue(startButton.waitForExistence(timeout: 2.0), "Start button should be visible again")
        }
    }

    // MARK: - Flow Test 3: Timer Countdown Verification

    /// Tests that timer actually counts down and validates format
    func testTimerCountdown() {
        self.navigateToTimerTab()

        // Start timer
        self.app.buttons["timer.button.start"].tap()

        // Wait for timer display
        let timerDisplay = self.app.staticTexts["timer.display.time"]
        XCTAssertTrue(timerDisplay.waitForExistence(timeout: 3.0), "Timer display should appear")

        let initialTime = timerDisplay.label

        // Wait for time to change
        let predicate = NSPredicate(format: "label != %@", initialTime)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: timerDisplay)
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(result, .completed, "Timer should count down")

        let laterTime = timerDisplay.label
        XCTAssertNotEqual(initialTime, laterTime, "Timer should have counted down")

        // Verify format is correct (MM:SS or just seconds for countdown)
        let timePattern = "[0-9]{1,2}(:[0-9]{2})?"
        XCTAssertTrue(laterTime.range(of: timePattern, options: .regularExpression) != nil)
    }

    // MARK: - Flow Test 4: Timer State Navigation

    /// Tests navigation through all timer states
    func testTimerStateNavigation() {
        self.navigateToTimerTab()

        // Start timer
        self.app.buttons["timer.button.start"].tap()

        // Wait for running state
        let pauseButton = self.app.buttons["timer.button.pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0), "Should be in running state")

        // Running -> Paused
        pauseButton.tap()
        XCTAssertTrue(self.app.buttons["timer.button.resume"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(self.app.staticTexts["timer.state.text"].waitForExistence(timeout: 2.0))

        // Paused -> Running
        self.app.buttons["timer.button.resume"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.pause"].waitForExistence(timeout: 2.0))

        // Running -> Idle (end timer)
        self.app.buttons["timer.button.end"].tap()
        XCTAssertTrue(self.app.buttons["timer.button.start"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(self.app.staticTexts["timer.duration.question"].waitForExistence(timeout: 2.0))
    }
}
