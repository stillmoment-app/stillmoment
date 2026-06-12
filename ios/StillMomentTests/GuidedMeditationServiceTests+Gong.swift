//
//  GuidedMeditationServiceTests+Gong.swift
//  Still Moment
//
//  Persistence tests for the per-meditation gong setting (shared-106)
//

import XCTest
@testable import StillMoment

extension GuidedMeditationServiceTests {
    func testGongSettingPersistsAcrossSaveAndLoad() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var meditation = self.createTestMeditation(teacher: "Teacher", name: "With Gong")
        meditation.gongEnabled = true

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.gongEnabled, true)
    }

    func testUpdateMeditationPersistsGongChange() throws {
        // Given: a meditation persisted without gong
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Teacher", name: "No Gong")
        try sut.saveMeditations([meditation])

        // When: user enables the gong in the edit sheet
        var edited = meditation
        edited.gongEnabled = true
        try sut.updateMeditation(edited)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.first?.gongEnabled, true)
    }

    func testGongSoundChoicePersistsAcrossSaveAndLoad() throws {
        // Given: the user picked a sound for this meditation in the edit sheet
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var meditation = self.createTestMeditation(teacher: "Teacher", name: "Own Sound")
        meditation.gongEnabled = true
        meditation.gongSoundId = "deep-resonance"

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.gongSoundId, "deep-resonance")
    }

    func testMeditationWithoutGongStaysDisabledAfterReload() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Teacher", name: "Plain")

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.gongEnabled, false)
    }
}
