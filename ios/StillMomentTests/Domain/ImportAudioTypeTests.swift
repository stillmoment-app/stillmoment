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

    // MARK: - CustomAudioType Mapping

    func testSoundscape_mapsToCustomAudioTypeSoundscape() {
        XCTAssertEqual(ImportAudioType.soundscape.customAudioType, .soundscape)
    }

    func testGuidedMeditation_hasNoCustomAudioType() {
        XCTAssertNil(ImportAudioType.guidedMeditation.customAudioType)
    }

    // MARK: - Equatable

    func testImportAudioType_differentCases_areNotEqual() {
        XCTAssertNotEqual(ImportAudioType.guidedMeditation, ImportAudioType.soundscape)
    }
}
