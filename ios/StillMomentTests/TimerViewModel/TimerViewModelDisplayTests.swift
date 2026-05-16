//
//  TimerViewModelDisplayTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests fuer Display-Properties des Running-Timer-Screens (ios-046):
/// `formattedRemainingMMSS` und `runningSubLabel`.
@MainActor
final class TimerViewModelDisplayTests: XCTestCase {
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

    // MARK: - formattedRemainingMMSS

    func testFormattedRemainingMMSSAtFullHour() {
        // Given Restzeit volle Stunde (60 Minuten)
        self.sut.timer = MeditationTimer(
            durationMinutes: 60,
            remainingSeconds: 3600,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then MM:SS mit Minuten-Padding
        XCTAssertEqual(self.sut.formattedRemainingMMSS, "60:00")
    }

    func testFormattedRemainingMMSSWithMixedValue() {
        // Given Restzeit 7 min 36 s (456 s)
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 456,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then beide Komponenten zweistellig
        XCTAssertEqual(self.sut.formattedRemainingMMSS, "07:36")
    }

    func testFormattedRemainingMMSSBelowOneMinute() {
        // Given Restzeit 5 s
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 5,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Minuten und Sekunden zweistellig
        XCTAssertEqual(self.sut.formattedRemainingMMSS, "00:05")
    }

    func testFormattedRemainingMMSSAtZero() {
        // Given Sitzung am Ende
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 0,
            state: .endGong,
            preparationTimeSeconds: 0
        )

        // Then "00:00"
        XCTAssertEqual(self.sut.formattedRemainingMMSS, "00:00")
    }

    func testFormattedRemainingMMSSAtOneSecond() {
        // Given Restzeit 1 s
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 1,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then "00:01"
        XCTAssertEqual(self.sut.formattedRemainingMMSS, "00:01")
    }

    // MARK: - runningSubLabel

    func testRunningSubLabelSingular() {
        // Given 1 Minute Sitzungsdauer
        self.sut.timer = MeditationTimer(
            durationMinutes: 1,
            remainingSeconds: 60,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Singular-Variante wird verwendet (Schluessel timer.running.duration.singular).
        let expected = String(
            format: NSLocalizedString("timer.running.duration.singular", comment: ""),
            1
        )
        XCTAssertEqual(self.sut.runningSubLabel, expected)
    }

    func testRunningSubLabelPlural() {
        // Given 10 Minuten Sitzungsdauer
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 600,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Plural-Variante wird verwendet.
        let expected = String(
            format: NSLocalizedString("timer.running.duration.plural", comment: ""),
            10
        )
        XCTAssertEqual(self.sut.runningSubLabel, expected)
    }

    func testRunningSubLabelUsesTotalDurationNotRemaining() {
        // Given Sitzung mit 10 Minuten, Restzeit nur noch 1 Minute.
        // Sub-Label soll trotzdem "von 10 Minuten" zeigen, nicht "von 1 Minute".
        self.sut.timer = MeditationTimer(
            durationMinutes: 10,
            remainingSeconds: 60,
            state: .running,
            preparationTimeSeconds: 0
        )

        // Then Plural-Variante mit 10 Minuten.
        let expected = String(
            format: NSLocalizedString("timer.running.duration.plural", comment: ""),
            10
        )
        XCTAssertEqual(self.sut.runningSubLabel, expected)
    }
}
