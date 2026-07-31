//
//  DurationFilterTests.swift
//  Still Moment
//
//  Tests fuer den Dauer-Filter der Bibliothek (shared-081).
//

import XCTest
@testable import StillMoment

final class DurationFilterTests: XCTestCase {
    // MARK: - Grenzwerte der Stufen

    func testMeditationJustUnderFiveMinutesFallsIntoShortestStep() {
        let meditation = self.makeMeditation(seconds: 299) // 4:59

        XCTAssertTrue(DurationFilter.upTo5.matches(meditation))
        XCTAssertFalse(DurationFilter.from5To15.matches(meditation))
    }

    func testMeditationOfExactlyFiveMinutesFallsIntoSecondStep() {
        let meditation = self.makeMeditation(seconds: 300) // 5:00

        XCTAssertFalse(DurationFilter.upTo5.matches(meditation))
        XCTAssertTrue(DurationFilter.from5To15.matches(meditation))
    }

    func testMeditationJustUnderFifteenMinutesStaysInSecondStep() {
        let meditation = self.makeMeditation(seconds: 899) // 14:59

        XCTAssertTrue(DurationFilter.from5To15.matches(meditation))
        XCTAssertFalse(DurationFilter.from15To30.matches(meditation))
    }

    func testMeditationOfExactlyFifteenMinutesFallsIntoThirdStep() {
        let meditation = self.makeMeditation(seconds: 900) // 15:00

        XCTAssertFalse(DurationFilter.from5To15.matches(meditation))
        XCTAssertTrue(DurationFilter.from15To30.matches(meditation))
    }

    func testMeditationJustUnderThirtyMinutesStaysInThirdStep() {
        let meditation = self.makeMeditation(seconds: 1799) // 29:59

        XCTAssertTrue(DurationFilter.from15To30.matches(meditation))
        XCTAssertFalse(DurationFilter.over30.matches(meditation))
    }

    func testMeditationOfExactlyThirtyMinutesFallsIntoLongestStep() {
        let meditation = self.makeMeditation(seconds: 1800) // 30:00

        XCTAssertFalse(DurationFilter.from15To30.matches(meditation))
        XCTAssertTrue(DurationFilter.over30.matches(meditation))
    }

    // MARK: - `Alle`

    func testAllStepMatchesEveryDuration() {
        let durations: [TimeInterval] = [0, 299, 300, 900, 1800, 7200]

        for seconds in durations {
            XCTAssertTrue(
                DurationFilter.all.matches(self.makeMeditation(seconds: seconds)),
                "`Alle` muss \(seconds)s einschliessen"
            )
        }
    }

    // MARK: - Getrimmte Meditationen

    func testTrimmedMeditationIsFilteredByTheDurationShownInTheList() {
        // 42-Minuten-Datei, auf 12 Minuten getrimmt — die Liste zeigt 12:00.
        let meditation = self.makeMeditation(seconds: 2520, trimStart: 0, trimEnd: 720)

        XCTAssertTrue(DurationFilter.from5To15.matches(meditation))
        XCTAssertFalse(DurationFilter.over30.matches(meditation))
    }

    // MARK: - Filtern einer Bibliothek

    func testApplyingStepKeepsOnlyMatchingMeditations() {
        let library = self.makeLibrary()

        let filtered = DurationFilter.from5To15.apply(to: library)

        XCTAssertEqual(filtered.map(\.name), ["05:00", "14:59"])
    }

    func testApplyingAllKeepsTheWholeLibraryInOrder() {
        let library = self.makeLibrary()

        let filtered = DurationFilter.all.apply(to: library)

        XCTAssertEqual(filtered.map(\.name), library.map(\.name))
    }

    // MARK: - Belegte Stufen

    func testStepWithoutAnyMeditationIsNotAvailable() {
        // Kuerzeste Meditation ist 5:00 — die Stufe „bis 5 Min" bleibt leer.
        let library = [self.makeMeditation(seconds: 300), self.makeMeditation(seconds: 1200)]

        let available = DurationFilter.availableSteps(in: library)

        XCTAssertFalse(available.contains(.upTo5))
        XCTAssertTrue(available.contains(.from5To15))
        XCTAssertTrue(available.contains(.from15To30))
        XCTAssertFalse(available.contains(.over30))
    }

    func testLibraryCoveringEveryStepMakesAllStepsAvailable() {
        let available = DurationFilter.availableSteps(in: self.makeLibrary())

        XCTAssertEqual(available, Set(DurationFilter.allCases))
    }

    func testAllStepIsAlwaysAvailable() {
        XCTAssertTrue(DurationFilter.availableSteps(in: self.makeLibrary()).contains(.all))
        XCTAssertTrue(DurationFilter.availableSteps(in: []).contains(.all))
    }

    func testEmptyLibraryLeavesOnlyTheAllStep() {
        let available = DurationFilter.availableSteps(in: [])

        XCTAssertEqual(available, [.all])
    }

    // MARK: - Helpers

    /// Bibliothek mit je einer Meditation an jeder Stufengrenze.
    private func makeLibrary() -> [GuidedMeditation] {
        [299, 300, 899, 900, 1799, 1800].map { seconds in
            self.makeMeditation(seconds: TimeInterval(seconds), name: self.label(for: seconds))
        }
    }

    private func label(for seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func makeMeditation(
        seconds: TimeInterval,
        name: String = "Test",
        trimStart: TimeInterval? = nil,
        trimEnd: TimeInterval? = nil
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: seconds,
            teacher: "Tara Brach",
            name: name,
            trimStart: trimStart,
            trimEnd: trimEnd
        )
    }
}
