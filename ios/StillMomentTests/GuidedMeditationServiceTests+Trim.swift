//
//  GuidedMeditationServiceTests+Trim.swift
//  Still Moment
//
//  Persistence tests for trim points (shared-105)
//

import XCTest
@testable import StillMoment

extension GuidedMeditationServiceTests {
    func testTrimPointsPersistAcrossSaveAndLoad() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var meditation = self.createTestMeditation(teacher: "Teacher", name: "Trimmed")
        meditation.trimStart = 30
        meditation.trimEnd = 540

        // When
        try sut.saveMeditations([meditation])
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.first?.trimStart, 30)
        XCTAssertEqual(loaded.first?.trimEnd, 540)
    }

    func testUpdateMeditationPersistsTrimChange() throws {
        // Given: a meditation persisted without trim
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Teacher", name: "Untrimmed")
        try sut.saveMeditations([meditation])

        // When: user sets trim points in the edit sheet
        var edited = meditation
        edited.trimStart = 45
        edited.trimEnd = 500
        try sut.updateMeditation(edited)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.first?.trimStart, 45)
        XCTAssertEqual(loaded.first?.trimEnd, 500)
    }

    func testMeditationWithoutTrimStaysUntrimmedAfterReload() throws {
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
        XCTAssertNil(loaded.first?.trimStart)
        XCTAssertNil(loaded.first?.trimEnd)
    }
}
