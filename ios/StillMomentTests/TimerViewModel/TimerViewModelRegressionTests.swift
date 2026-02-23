//
//  TimerViewModelRegressionTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Critical regression tests for known bugs that must NEVER regress
/// These tests protect against specific production issues that caused user-visible problems
@MainActor
final class TimerViewModelRegressionTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSettingsRepository: MockTimerSettingsRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        super.tearDown()
    }

    // MARK: - Lock Screen Preparation Bug

    func testBackgroundAudioStartsWhenMeditationBegins() {
        // Background audio starts when the start gong finishes (via startGongFinished),
        // not immediately on startPressed. This keeps the preparation phase silent.

        // Given
        self.sut.selectedMinutes = 1

        // When - Start timer (preparation phase)
        self.sut.startTimer()

        // Then - Background audio must NOT be started yet
        XCTAssertFalse(
            self.mockAudioService.startBackgroundAudioCalled,
            "Background audio must not start during preparation"
        )

        // When - Preparation finishes → startGong state
        self.sut.timer = .stub(durationMinutes: 1, state: .startGong)
        self.sut.dispatch(.preparationFinished)

        // Then - Background audio must NOT be started yet (still playing gong)
        XCTAssertFalse(
            self.mockAudioService.startBackgroundAudioCalled,
            "Background audio must not start during start gong"
        )

        // When - Start gong finishes → running with background audio
        self.sut.dispatch(.startGongFinished)

        // Then - Background audio starts now
        XCTAssertTrue(
            self.mockAudioService.startBackgroundAudioCalled,
            "Background audio must start when start gong finishes"
        )

        // Critical: Verify timer session was activated before background audio starts
        let activateIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "activateTimerSession")
        let startBackgroundIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "startBackgroundAudio")

        XCTAssertNotNil(activateIndex, "Timer session must be activated")
        XCTAssertNotNil(startBackgroundIndex, "Background audio must be started")

        if let activateIdx = activateIndex, let startIdx = startBackgroundIndex {
            XCTAssertLessThan(
                activateIdx,
                startIdx,
                "Timer session must be activated BEFORE background audio starts"
            )
        }
    }

    // MARK: - Completion Gong Silent Bug

    func testCompletionGongPlaysBeforeBackgroundAudioStops() {
        // CRITICAL: This test prevents the completion-gong-silence bug
        // Completion gong MUST play BEFORE background audio stops
        // Otherwise audio session gets deactivated and gong can't play (especially on locked screen)

        // Given
        let expectation = expectation(description: "Completion sequence")

        // When - Simulate timer completion
        self.mockTimerService.simulateCompletion()

        // Wait for completion handlers to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - Verify both were called
            XCTAssertTrue(
                self.mockAudioService.playCompletionSoundCalled,
                "Completion gong must play"
            )
            XCTAssertTrue(
                self.mockAudioService.stopBackgroundAudioCalled,
                "Background audio must stop"
            )

            // Critical: Verify completion gong played BEFORE background audio stopped
            let gongIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "playCompletionSound")
            let stopIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "stopBackgroundAudio")

            XCTAssertNotNil(gongIndex, "Completion gong must be played")
            XCTAssertNotNil(stopIndex, "Background audio must be stopped")

            if let gong = gongIndex, let stop = stopIndex {
                XCTAssertLessThan(
                    gong,
                    stop,
                    """
                    CRITICAL: Completion gong must play BEFORE background audio stops.
                    If background audio stops first, audio session deactivates and gong can't play.
                    """
                )
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Interval Gong Single Play Bug (ios-028)

    func testIntervalGongPlaysMultipleTimes_NotJustOnce() {
        // CRITICAL: This test prevents the interval-gong-single-play bug (ios-028)
        // Interval gong MUST play at EVERY interval, not just the first one
        // With shared-056, interval detection moved into tick() which emits TimerEvent.intervalGongDue.
        // The ViewModel dispatches .intervalGongTriggered for each event, and tick() internally
        // marks lastIntervalGongAt to enable detection of the next interval.

        // Given - Enable interval gongs (3 minute intervals for a 10 minute timer)
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.intervalMinutes = 3

        let expectation = expectation(description: "Multiple interval gongs")

        // When - Simulate reaching first interval at 3 minutes (180 seconds elapsed)
        self.mockTimerService.simulateTimerAtInterval(
            durationMinutes: 10,
            elapsedSeconds: 180
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            // Then - First interval gong should have played
            let firstGongCount = self.mockAudioService.audioCallOrder.filter { $0 == "playIntervalGong" }.count
            XCTAssertEqual(
                firstGongCount,
                1,
                "First interval gong should play at 3 minutes"
            )

            // When - Continue timer to second interval at 6 minutes (180 more seconds)
            // tick() internally detects the interval and emits .intervalGongDue
            let intervalSettings = IntervalSettings(
                intervalMinutes: 3,
                mode: self.sut.settings.intervalMode
            )
            self.mockTimerService.continueTimer(
                additionalSeconds: 180,
                intervalSettings: intervalSettings
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then - Second interval gong should have played
                let secondGongCount = self.mockAudioService.audioCallOrder.filter { $0 == "playIntervalGong" }.count
                XCTAssertEqual(
                    secondGongCount,
                    2,
                    """
                    CRITICAL: Interval gong must play at EVERY interval, not just the first.
                    Expected 2 interval gongs (at 3 min and 6 min), but only got \(secondGongCount).
                    Bug: tick() must internally mark lastIntervalGongAt and emit .intervalGongDue events.
                    """
                )

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Introduction Background Audio Bug

    func testBackgroundAudioStartsAfterIntroductionFinishes() {
        // CRITICAL: Regression test for the introduction→background-audio bug.
        // After Einstimmung finishes, Klangkulisse MUST start.
        // Bug: domain timer stayed in .startGong during introduction, so the
        // .introduction guard in reduceIntroductionFinished failed → no audio.

        // Given - Introduction configured (German locale required)
        Introduction.languageOverride = "de"
        defer { Introduction.languageOverride = nil }

        self.sut.settings.introductionId = "breath"
        self.sut.selectedMinutes = 5

        // When - Start timer (emits .startGong tick via mock)
        self.sut.startTimer()

        // When - Start gong finishes → triggers beginIntroductionPhase + playIntroduction
        // Set timer to startGong so reducer guard passes
        self.sut.timer = .stub(durationMinutes: 5, state: .startGong)
        self.sut.dispatch(.startGongFinished)

        // When - Introduction audio finishes → triggers endIntroductionPhase + startBackgroundAudio
        // Set timer to introduction so reducer guard passes
        self.sut.timer = .stub(durationMinutes: 5, state: .introduction)
        self.sut.dispatch(.introductionFinished)

        // Then - Background audio MUST have started
        XCTAssertTrue(
            self.mockAudioService.startBackgroundAudioCalled,
            """
            CRITICAL: Background audio must start after introduction finishes.
            Bug: domain timer was stuck in .startGong during introduction, causing
            reduceIntroductionFinished's guard to fail and skip all effects.
            """
        )
    }
}
