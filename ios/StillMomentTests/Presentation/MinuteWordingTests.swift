//
//  MinuteWordingTests.swift
//  Still Moment
//
//  Einzahl/Mehrzahl der Minuten-Einheit im Atemkreis und der Screenreader-Ansage
//  (shared-140). Geprueft wird je Sprache ueber das passende `.lproj`-Bundle,
//  damit Deutsch und Englisch unabhaengig von der Test-Locale abgedeckt sind.
//

import XCTest
@testable import StillMoment

final class MinuteWordingTests: XCTestCase {
    // MARK: - Einheit unter der Zahl im Atemkreis

    func testDialUnitIsSingularForOneMinuteInEnglish() throws {
        XCTAssertEqual(try self.unit(1, language: "en"), "Minute")
    }

    func testDialUnitIsPluralForTwoAndSixtyMinutesInEnglish() throws {
        XCTAssertEqual(try self.unit(2, language: "en"), "Minutes")
        XCTAssertEqual(try self.unit(60, language: "en"), "Minutes")
    }

    func testDialUnitIsSingularForOneMinuteInGerman() throws {
        XCTAssertEqual(try self.unit(1, language: "de"), "Minute")
    }

    func testDialUnitIsPluralForTwoAndSixtyMinutesInGerman() throws {
        XCTAssertEqual(try self.unit(2, language: "de"), "Minuten")
        XCTAssertEqual(try self.unit(60, language: "de"), "Minuten")
    }

    func testDialUnitChangesWhenDurationMovesBetweenOneAndTwo() {
        // Die Einheit haengt allein an der aktuellen Minutenzahl — wechselt der Wert
        // im Atemkreis, wechselt die Einheit beim naechsten Rendern mit.
        XCTAssertNotEqual(MinuteWording.unit(for: 1), MinuteWording.unit(for: 2))
        XCTAssertEqual(MinuteWording.unit(for: 2), MinuteWording.unit(for: 60))
    }

    // MARK: - Screenreader-Wert des Atemkreises

    func testSpokenDurationInEnglish() throws {
        XCTAssertEqual(try self.spoken(1, language: "en"), "1 minute")
        XCTAssertEqual(try self.spoken(2, language: "en"), "2 minutes")
        XCTAssertEqual(try self.spoken(60, language: "en"), "60 minutes")
    }

    func testSpokenDurationInGerman() throws {
        XCTAssertEqual(try self.spoken(1, language: "de"), "1 Minute")
        XCTAssertEqual(try self.spoken(2, language: "de"), "2 Minuten")
        XCTAssertEqual(try self.spoken(60, language: "de"), "60 Minuten")
    }

    // MARK: - Bereits korrekte Stellen: Intervall-Hinweistexte

    func testIntervalHelpTextUsesSingularForOneMinute() throws {
        XCTAssertEqual(
            try self.intervalHelp(.repeating, minutes: 1, language: "en"),
            "A gong sounds every minute throughout the session."
        )
        XCTAssertEqual(
            try self.intervalHelp(.repeating, minutes: 2, language: "en"),
            "A gong sounds every 2 minutes throughout the session."
        )
        XCTAssertFalse(try self.intervalHelp(.afterStart, minutes: 1, language: "de").contains("Minuten"))
        XCTAssertTrue(try self.intervalHelp(.afterStart, minutes: 2, language: "de").contains("2 Minuten"))
    }

    // MARK: - Helpers

    private func intervalHelp(_ mode: IntervalMode, minutes: Int, language: String) throws -> String {
        let format = try self.bundle(language).localizedString(forKey: mode.modeHelpKey, value: nil, table: nil)
        return String.localizedStringWithFormat(format, minutes)
    }

    private func unit(_ minutes: Int, language: String) throws -> String {
        try MinuteWording.unit(for: minutes, bundle: self.bundle(language))
    }

    private func spoken(_ minutes: Int, language: String) throws -> String {
        try MinuteWording.spokenDuration(for: minutes, bundle: self.bundle(language))
    }

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }
}
