//
//  GuidedMeditationServiceTests+Gong.swift
//  Still Moment
//
//  Persistence tests for the per-meditation gong settings (shared-106)
//

import XCTest
@testable import StillMoment

extension GuidedMeditationServiceTests {
    func testGongSettingsPersistAcrossSaveAndLoad() throws {
        // Given: only the end gong is enabled
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var meditation = self.createTestMeditation(teacher: "Teacher", name: "With Gong")
        meditation.endGongEnabled = true

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.startGongEnabled, false)
        XCTAssertEqual(loaded.first?.endGongEnabled, true)
    }

    func testUpdateMeditationPersistsGongChange() throws {
        // Given: a meditation persisted without gongs
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Teacher", name: "No Gong")
        try sut.saveMeditations([meditation])

        // When: user enables the start gong in the edit sheet
        var edited = meditation
        edited.startGongEnabled = true
        try sut.updateMeditation(edited)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.first?.startGongEnabled, true)
        XCTAssertEqual(loaded.first?.endGongEnabled, false)
    }

    func testGongSoundChoicePersistsAcrossSaveAndLoad() throws {
        // Given: the user picked a sound for this meditation in the edit sheet
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var meditation = self.createTestMeditation(teacher: "Teacher", name: "Own Sound")
        meditation.startGongEnabled = true
        meditation.gongSoundId = "deep-resonance"

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.gongSoundId, "deep-resonance")
    }

    func testAddMeditationPersistsGongSettingsChosenAtImport() throws {
        // Given: the user enabled both gongs and picked a sound in the import sheet (ios-062)
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let tempURL = self.createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.removeItem(at: sut.getMeditationsDirectory())
        }

        var draft = self.makeImportDraft(for: tempURL, teacher: "Teacher", name: "Imported With Gong")
        draft.startGongEnabled = true
        draft.endGongEnabled = true
        draft.gongSoundId = "deep-resonance"

        // When
        _ = try sut.addMeditation(from: tempURL, draft: draft)

        // Then: the settings survive a reload, on the very entry the user edited
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.first?.id, draft.id)
        XCTAssertEqual(loaded.first?.startGongEnabled, true)
        XCTAssertEqual(loaded.first?.endGongEnabled, true)
        XCTAssertEqual(loaded.first?.gongSoundId, "deep-resonance")
    }

    func testMeditationWithoutGongsStaysDisabledAfterReload() throws {
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
        XCTAssertEqual(loaded.first?.startGongEnabled, false)
        XCTAssertEqual(loaded.first?.endGongEnabled, false)
    }
}
