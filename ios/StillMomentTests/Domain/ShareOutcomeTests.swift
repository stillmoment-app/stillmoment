//
//  ShareOutcomeTests.swift
//  Still Moment
//
//  ios-059: Was die Share-Extension nach dem Teilen zeigt — Bestaetigung oder welche Meldung.
//

import XCTest
@testable import StillMoment

final class ShareOutcomeTests: XCTestCase {
    // MARK: - Geteilte Audiodatei

    func testSharedMP3IsConfirmed() {
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Atemraum.mp3"))), .confirmation)
    }

    func testSharedM4AIsConfirmed() {
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Bodyscan.m4a"))), .confirmation)
    }

    func testFileExtensionInCapitalLettersIsConfirmed() {
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Bodyscan.M4A"))), .confirmation)
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Atemraum.Mp3"))), .confirmation)
    }

    func testSharedWAVIsRejectedAsUnsupportedFormat() {
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Aufnahme.wav"))), .unsupportedFormat)
    }

    func testAudioFileWithoutExtensionIsRejectedAsUnsupportedFormat() {
        XCTAssertEqual(ShareOutcome.evaluate(.audioFile(self.file("Aufnahme"))), .unsupportedFormat)
    }

    // MARK: - Geteilter Link

    func testSharedWebPageIsConfirmed() throws {
        let https = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/25401"))
        let http = try XCTUnwrap(URL(string: "http://www.tarabrach.com/guided-meditations"))

        XCTAssertEqual(ShareOutcome.evaluate(.link(https)), .confirmation)
        XCTAssertEqual(ShareOutcome.evaluate(.link(http)), .confirmation)
    }

    func testWebAddressSchemeInCapitalLettersIsConfirmed() throws {
        let url = try XCTUnwrap(URL(string: "HTTPS://www.audiodharma.org/talks/25401"))

        XCTAssertEqual(ShareOutcome.evaluate(.link(url)), .confirmation)
    }

    func testMailAddressIsNoLink() throws {
        let url = try XCTUnwrap(URL(string: "mailto:lehrerin@example.org"))

        XCTAssertEqual(ShareOutcome.evaluate(.link(url)), .noLink)
    }

    func testLinksThatAreNoWebAddressAreNoLink() throws {
        for address in ["ftp://example.org/talk.mp3", "tel:+49301234567", "file:///tmp/talk.mp3"] {
            let url = try XCTUnwrap(URL(string: address))

            XCTAssertEqual(ShareOutcome.evaluate(.link(url)), .noLink, "\(address) ist keine Webadresse")
        }
    }

    // MARK: - Nichts Verwertbares

    func testMissingOrUnreadableContentIsReportedAsUnreadable() {
        XCTAssertEqual(ShareOutcome.evaluate(.nothing), .unreadable)
    }

    // MARK: - Helpers

    private func file(_ name: String) -> URL {
        URL(fileURLWithPath: "/tmp/share").appendingPathComponent(name)
    }
}
