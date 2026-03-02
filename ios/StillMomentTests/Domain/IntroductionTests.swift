//
//  IntroductionTests.swift
//  Still Moment
//
//  Tests for Introduction domain model
//

import XCTest
@testable import StillMoment

final class IntroductionTests: XCTestCase {
    // MARK: - Static Definitions

    func testBreath_hasCorrectId() {
        XCTAssertEqual(Introduction.breath.id, "breath")
    }

    func testBreath_hasCorrectDuration() {
        XCTAssertEqual(Introduction.breath.durationSeconds, 95)
    }

    func testBreath_isAvailableInGerman() {
        XCTAssertTrue(Introduction.breath.availableLanguages.contains("de"))
    }

    func testBreath_isAvailableInEnglish() {
        XCTAssertTrue(Introduction.breath.availableLanguages.contains("en"))
    }

    func testAllIntroductions_containsBreath() {
        XCTAssertTrue(Introduction.allIntroductions.contains(Introduction.breath))
    }

    // MARK: - Audio Filename

    func testAudioFilename_forAvailableLanguage_returnsFilename() {
        let filename = Introduction.breath.audioFilename(for: "de")
        XCTAssertEqual(filename, "intro-breath-de.mp3")
    }

    func testAudioFilename_forEnglish_returnsFilename() {
        let filename = Introduction.breath.audioFilename(for: "en")
        XCTAssertEqual(filename, "intro-breath-en.mp3")
    }

    func testAudioFilename_forUnknownLanguage_returnsNil() {
        let filename = Introduction.breath.audioFilename(for: "fr")
        XCTAssertNil(filename)
    }

    // MARK: - Formatted Duration

    func testFormattedDuration_showsMinutesAndSeconds() {
        XCTAssertEqual(Introduction.breath.formattedDuration, "1:35")
    }

    // MARK: - Localized Name

    func testName_isNonEmpty() {
        XCTAssertFalse(Introduction.breath.name.isEmpty)
    }

    // MARK: - Registry: find(byId:)

    func testFindById_existingId_returnsIntroduction() {
        let intro = Introduction.find(byId: "breath")
        XCTAssertNotNil(intro)
        XCTAssertEqual(intro?.id, "breath")
    }

    func testFindById_unknownId_returnsNil() {
        let intro = Introduction.find(byId: "nonexistent")
        XCTAssertNil(intro)
    }

    // MARK: - Equatable

    func testEquatable_sameIntroduction_areEqual() {
        let intro1 = Introduction.breath
        let intro2 = Introduction.breath
        XCTAssertEqual(intro1, intro2)
    }

    // MARK: - Identifiable

    func testIdentifiable_usesIdProperty() {
        let intro = Introduction.breath
        XCTAssertEqual(intro.id, "breath")
    }
}
