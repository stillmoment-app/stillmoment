//
//  TimerViewModelPhaseTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests fuer phase + formattedRemainingMinutes — die computed Properties,
/// die der Timer-Atemkreis (BreathingCircleView) und das Restzeit-Label nutzen.
@MainActor
final class TimerViewModelPhaseTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!

    override func setUp() {
        super.setUp()
        self.sut = TimerViewModel(
            timerService: MockTimerService(),
            audioService: MockAudioService(),
            praxisRepository: MockPraxisRepository()
        )
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    // MARK: - phase

    func testPhaseInPreparation() {
        // Given Timer in Pre-Roll-Phase
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 600,
            state: .preparation,
            remainingPreparationSeconds: 6,
            preparationTimeSeconds: 6
        )

        // Then visuelle Phase ist Pre-Roll
        XCTAssertEqual(self.sut.phase, .preRoll)
    }

    func testPhaseInRunning() {
        // Given Timer in Running-State
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 512,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then visuelle Phase ist Hauptphase
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhaseInStartGong() {
        // Given StartGong (kurz nach Pre-Roll-Ende)
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 600,
            state: .startGong,
            preparationTimeSeconds: 0
        )

        // Then Hauptphase — Atemkreis verhaelt sich wie running
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhaseInEndGong() {
        // Given EndGong
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 0,
            state: .endGong,
            preparationTimeSeconds: 0
        )

        // Then Hauptphase
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhaseWhenIdle() {
        // Given kein Timer aktiv (idle)
        self.sut.timer = nil

        // Then Hauptphase als Default — der Pre-Roll-Pfad wird nur waehrend
        // einer aktiven Sitzung gerendert, dieser Default ist nur ein Sicherheitsnetz.
        XCTAssertEqual(self.sut.phase, .playing)
    }

    // MARK: - formattedRemainingMinutes

    func testFormattedRemainingMinutesFormatsAsMmSs() {
        // Given Restzeit 8:32 (512 s)
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 512,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Player-Format ohne Minuten-Padding
        XCTAssertEqual(self.sut.formattedRemainingMinutes, "8:32")
    }

    func testFormattedRemainingMinutesPadsSecondsBelowTen() {
        // Given Restzeit 0:45
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 45,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Sekunden zweistellig
        XCTAssertEqual(self.sut.formattedRemainingMinutes, "0:45")
    }

    func testFormattedRemainingMinutesZeroAtEnd() {
        // Given Restzeit 0
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 0,
            state: .endGong,
            preparationTimeSeconds: 0
        )

        // Then "0:00"
        XCTAssertEqual(self.sut.formattedRemainingMinutes, "0:00")
    }
}
