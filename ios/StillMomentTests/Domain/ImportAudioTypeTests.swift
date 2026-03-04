//
//  ImportAudioTypeTests.swift
//  Still Moment
//
//  Domain Tests - ImportAudioType Model
//

import XCTest
@testable import StillMoment

final class ImportAudioTypeTests: XCTestCase {
    // MARK: - Type Existence

    func testImportAudioType_hasGuidedMeditationCase() {
        let type: ImportAudioType = .guidedMeditation
        XCTAssertEqual(type, .guidedMeditation)
    }

    func testImportAudioType_hasSoundscapeCase() {
        let type: ImportAudioType = .soundscape
        XCTAssertEqual(type, .soundscape)
    }

    func testImportAudioType_hasAttunementCase() {
        let type: ImportAudioType = .attunement
        XCTAssertEqual(type, .attunement)
    }

    // MARK: - CustomAudioType Mapping

    func testSoundscape_mapsToCustomAudioTypeSoundscape() {
        XCTAssertEqual(ImportAudioType.soundscape.customAudioType, .soundscape)
    }

    func testAttunement_mapsToCustomAudioTypeAttunement() {
        XCTAssertEqual(ImportAudioType.attunement.customAudioType, .attunement)
    }

    func testGuidedMeditation_hasNoCustomAudioType() {
        XCTAssertNil(ImportAudioType.guidedMeditation.customAudioType)
    }

    // MARK: - Equatable

    func testImportAudioType_differentCases_areNotEqual() {
        XCTAssertNotEqual(ImportAudioType.guidedMeditation, ImportAudioType.soundscape)
        XCTAssertNotEqual(ImportAudioType.soundscape, ImportAudioType.attunement)
        XCTAssertNotEqual(ImportAudioType.guidedMeditation, ImportAudioType.attunement)
    }
}
