//
//  LibraryCountLinePluralTests.swift
//  Still Moment
//
//  Tests fuer die Plural-Aufloesung der Zaehlzeile (shared-081).
//
//  Der Eintrag `library.list.countOfTotal` liegt in der `.stringsdict` und waehlt
//  die Plural-Form ueber das **zweite** Argument (den Gesamtbestand). Die Tests
//  vergleichen nur den Wortanteil, sind also unabhaengig von der Test-Locale.
//

import XCTest
@testable import StillMoment

final class LibraryCountLinePluralTests: XCTestCase {
    func testLibraryWithASingleMeditationReadsDifferentlyThanALargerOne() {
        // „1 von 1 Meditation" vs. „1 von 7 Meditationen".
        let singleLibrary = self.wording(visible: 1, total: 1)
        let largerLibrary = self.wording(visible: 1, total: 7)

        XCTAssertNotEqual(singleLibrary, largerLibrary)
    }

    func testPluralFormFollowsTheLibraryTotalNotTheVisibleCount() {
        // Die sichtbare Zahl ist in beiden Faellen 5, nur der Gesamtbestand wechselt.
        // Haenge der Plural am ersten Argument, waere kein Unterschied messbar.
        let totalOne = self.wording(visible: 5, total: 1)
        let totalSeven = self.wording(visible: 5, total: 7)

        XCTAssertNotEqual(totalOne, totalSeven)
    }

    func testCountLineNamesBothNumbers() {
        let line = self.countLine(visible: 2, total: 7)

        XCTAssertTrue(line.contains("2"), "Sichtbare Anzahl fehlt: \(line)")
        XCTAssertTrue(line.contains("7"), "Gesamtbestand fehlt: \(line)")
    }

    func testCountLineIsResolvedAndNotTheRawKey() {
        let line = self.countLine(visible: 2, total: 7)

        XCTAssertFalse(line.contains("countOfTotal"), "Roher L10n-Key im UI: \(line)")
        XCTAssertFalse(line.contains("%"), "Unaufgeloester Platzhalter: \(line)")
    }

    // MARK: - Helpers

    /// Der Wortanteil der Zaehlzeile ohne Ziffern — die Plural-Form allein.
    private func wording(visible: Int, total: Int) -> String {
        self.countLine(visible: visible, total: total).filter { !$0.isNumber }
    }

    private func countLine(visible: Int, total: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("library.list.countOfTotal", comment: ""),
            visible,
            total
        )
    }
}
