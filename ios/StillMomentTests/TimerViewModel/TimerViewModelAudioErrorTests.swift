//
//  TimerViewModelAudioErrorTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// When a sound cannot be played during a silent meditation, the user sees one calm,
/// localized message — never English-only or technical error details.
@MainActor
final class TimerViewModelAudioErrorTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!

    private var expectedMessage: String {
        NSLocalizedString("error.timerSoundFailed", comment: "")
    }

    override func setUp() {
        super.setUp()
        self.mockAudioService = MockAudioService()
        self.sut = TimerViewModel(
            timerService: MockTimerService(),
            audioService: self.mockAudioService,
            soundRepository: MockBackgroundSoundRepository(),
            praxisRepository: MockPraxisRepository(),
            customAudioRepository: MockCustomAudioRepository(),
            soundscapeResolver: MockSoundscapeResolver()
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockAudioService = nil
        super.tearDown()
    }

    func testStartGongFails_userSeesLocalizedMessageWithoutTechnicalDetails() {
        // Given
        self.mockAudioService.shouldThrowOnPlay = true

        // When
        self.sut.dispatch(.preparationFinished)

        // Then
        XCTAssertTrue(self.mockAudioService.playStartGongCalled)
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.playbackFailed)
    }

    func testTimerSessionCannotBePrepared_userSeesLocalizedMessage() {
        // Given
        self.mockAudioService.shouldThrowOnConfigure = true

        // When
        self.sut.startTimer()

        // Then
        XCTAssertTrue(self.mockAudioService.activateTimerSessionCalled)
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.sessionConfigurationFailed)
    }

    func testBackgroundSoundFails_userSeesLocalizedMessage() {
        // Given
        self.sut.timer = .stub(remainingSeconds: 300, state: .startGong)
        self.mockAudioService.shouldThrowOnPlay = true

        // When
        self.sut.dispatch(.startGongFinished)

        // Then
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.playbackFailed)
    }

    func testIntervalGongFails_userSeesLocalizedMessage() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.mockAudioService.shouldThrowOnPlay = true

        // When
        self.sut.dispatch(.intervalGongTriggered)

        // Then
        XCTAssertTrue(self.mockAudioService.playIntervalGongCalled)
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.playbackFailed)
    }

    func testEndGongFails_userSeesLocalizedMessage() {
        // Given
        self.mockAudioService.shouldThrowOnPlay = true

        // When
        self.sut.dispatch(.timerCompleted)

        // Then
        XCTAssertTrue(self.mockAudioService.playCompletionSoundCalled)
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.playbackFailed)
    }

    // MARK: - Next Meditation

    func testStartingNextMeditation_previousSoundMessageDisappears() {
        // Given: a sound failed in the previous meditation
        self.mockAudioService.shouldThrowOnPlay = true
        self.sut.dispatch(.timerCompleted)
        XCTAssertNotNil(self.sut.errorMessage)
        self.mockAudioService.shouldThrowOnPlay = false

        // When
        self.sut.startTimer()

        // Then
        XCTAssertNil(self.sut.errorMessage)
    }

    func testSoundFailsInNextMeditation_userSeesMessageAgain() {
        // Given: a sound failed in the previous meditation
        self.mockAudioService.shouldThrowOnPlay = true
        self.sut.dispatch(.timerCompleted)
        self.mockAudioService.shouldThrowOnPlay = false
        self.mockAudioService.shouldThrowOnConfigure = true

        // When: the next meditation cannot prepare its audio
        self.sut.startTimer()

        // Then
        self.assertShowsCalmSoundMessage(technicalError: AudioServiceError.sessionConfigurationFailed)
    }

    // MARK: - Helpers

    private func assertShowsCalmSoundMessage(
        technicalError: Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotEqual(
            self.expectedMessage,
            "error.timerSoundFailed",
            "Localization key missing",
            file: file,
            line: line
        )
        XCTAssertEqual(self.sut.errorMessage, self.expectedMessage, file: file, line: line)
        XCTAssertFalse(
            self.sut.errorMessage?.contains(technicalError.localizedDescription) ?? false,
            "Technical error details must not reach the user",
            file: file,
            line: line
        )
    }
}
