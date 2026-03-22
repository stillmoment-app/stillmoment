//
//  AttunementTests.swift
//  Still Moment
//
//  Tests for Attunement domain model
//

import XCTest
@testable import StillMoment

final class AttunementTests: XCTestCase {
    // MARK: - Static Definitions

    func testBreath_hasCorrectId() {
        XCTAssertEqual(Attunement.breath.id, "breath")
    }

    func testBreath_hasCorrectDuration() {
        XCTAssertEqual(Attunement.breath.durationSeconds, 95)
    }

    func testBreath_isAvailableInGerman() {
        XCTAssertTrue(Attunement.breath.availableLanguages.contains("de"))
    }

    func testBreath_isAvailableInEnglish() {
        XCTAssertTrue(Attunement.breath.availableLanguages.contains("en"))
    }

    func testAllAttunements_containsBreath() {
        XCTAssertTrue(Attunement.allAttunements.contains(Attunement.breath))
    }

    // MARK: - Audio Filename

    func testAudioFilename_forAvailableLanguage_returnsFilename() {
        let filename = Attunement.breath.audioFilename(for: "de")
        XCTAssertEqual(filename, "intro-breath-de.mp3")
    }

    func testAudioFilename_forEnglish_returnsFilename() {
        let filename = Attunement.breath.audioFilename(for: "en")
        XCTAssertEqual(filename, "intro-breath-en.mp3")
    }

    func testAudioFilename_forUnknownLanguage_returnsNil() {
        let filename = Attunement.breath.audioFilename(for: "fr")
        XCTAssertNil(filename)
    }

    // MARK: - Formatted Duration

    func testFormattedDuration_showsMinutesAndSeconds() {
        XCTAssertEqual(Attunement.breath.formattedDuration, "1:35")
    }

    // MARK: - Localized Name

    func testName_isNonEmpty() {
        XCTAssertFalse(Attunement.breath.name.isEmpty)
    }

    // MARK: - Registry: find(byId:)

    func testFindById_existingId_returnsAttunement() {
        let attunement = Attunement.find(byId: "breath")
        XCTAssertNotNil(attunement)
        XCTAssertEqual(attunement?.id, "breath")
    }

    func testFindById_unknownId_returnsNil() {
        let attunement = Attunement.find(byId: "nonexistent")
        XCTAssertNil(attunement)
    }

    // MARK: - Equatable

    func testEquatable_sameAttunement_areEqual() {
        let attunement1 = Attunement.breath
        let attunement2 = Attunement.breath
        XCTAssertEqual(attunement1, attunement2)
    }

    // MARK: - Identifiable

    func testIdentifiable_usesIdProperty() {
        let attunement = Attunement.breath
        XCTAssertEqual(attunement.id, "breath")
    }
}
