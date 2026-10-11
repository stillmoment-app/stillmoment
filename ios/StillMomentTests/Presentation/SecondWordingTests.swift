//
//  SecondWordingTests.swift
//  Still Moment
//
//  Einzahl/Mehrzahl der Sekunden in den Screenreader-Ansagen der
//  Vorbereitungszeit (shared-145). Geprueft wird je Sprache ueber das passende
//  `.lproj`-Bundle, damit Deutsch und Englisch unabhaengig von der Test-Locale
//  abgedeckt sind.
//

import XCTest
@testable import StillMoment

final class SecondWordingTests: XCTestCase {
    // MARK: - Timer: Ansage im Atemkreis und Wert des Dauer-Reglers

    func testPreparationAnnouncementInEnglish() throws {
        XCTAssertEqual(try self.preparation(1, language: "en"), "Preparation: 1 second")
        XCTAssertEqual(try self.preparation(2, language: "en"), "Preparation: 2 seconds")
        XCTAssertEqual(try self.preparation(45, language: "en"), "Preparation: 45 seconds")
    }

    func testPreparationAnnouncementInGerman() throws {
        XCTAssertEqual(try self.preparation(1, language: "de"), "Vorbereitung: 1 Sekunde")
        XCTAssertEqual(try self.preparation(2, language: "de"), "Vorbereitung: 2 Sekunden")
        XCTAssertEqual(try self.preparation(45, language: "de"), "Vorbereitung: 45 Sekunden")
    }

    // MARK: - Player einer gefuehrten Meditation

    func testCountdownAnnouncementInEnglish() throws {
        XCTAssertEqual(try self.countdown(1, language: "en"), "1 second until meditation starts")
        XCTAssertEqual(try self.countdown(2, language: "en"), "2 seconds until meditation starts")
    }

    func testCountdownAnnouncementInGerman() throws {
        XCTAssertEqual(try self.countdown(1, language: "de"), "1 Sekunde bis die Meditation beginnt")
        XCTAssertEqual(try self.countdown(2, language: "de"), "2 Sekunden bis die Meditation beginnt")
    }

    func testAnnouncementChangesBetweenOneAndTwoSecondsInAppLanguage() {
        // Die Ansage haengt allein an der aktuellen Sekundenzahl — beim Herunterzaehlen
        // von 2 auf 1 wechselt sie in die Einzahl, ohne Fallunterscheidung im View.
        XCTAssertFalse(SecondWording.preparation(for: 1).contains("1 seconds"))
        XCTAssertFalse(SecondWording.countdown(for: 1).contains("1 seconds"))
        XCTAssertFalse(SecondWording.preparation(for: 1).contains("1 Sekunden"))
        XCTAssertFalse(SecondWording.countdown(for: 1).contains("1 Sekunden"))
    }

    // MARK: - Helpers

    private func preparation(_ seconds: Int, language: String) throws -> String {
        try SecondWording.preparation(for: seconds, bundle: self.bundle(language))
    }

    private func countdown(_ seconds: Int, language: String) throws -> String {
        try SecondWording.countdown(for: seconds, bundle: self.bundle(language))
    }

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }
}
