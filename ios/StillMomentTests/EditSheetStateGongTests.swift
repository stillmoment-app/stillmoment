//
//  EditSheetStateGongTests.swift
//  Still Moment
//
//  Domain Tests - Gong setting in the edit sheet (shared-106)
//

import XCTest
@testable import StillMoment

final class EditSheetStateGongTests: XCTestCase {
    // MARK: - Prefill

    func testGongTogglePrefilledFromMeditation() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertTrue(state.editedGongEnabled)
    }

    func testGongToggleOffWhenMeditationHasNoGong() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: false)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertFalse(state.editedGongEnabled)
    }

    func testGongSoundPrefilledFromMeditation() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true, gongSoundId: "deep-resonance")

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedGongSoundId, "deep-resonance")
    }

    // MARK: - Change Detection

    func testTogglingGongCountsAsChange() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: false)
        var state = EditSheetState(meditation: meditation)
        XCTAssertFalse(state.hasChanges)

        // When
        state.editedGongEnabled = true

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testTogglingGongBackIsNoChange() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedGongEnabled = false
        state.editedGongEnabled = true

        // Then
        XCTAssertFalse(state.hasChanges)
    }

    func testChangingGongSoundCountsAsChange() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)
        var state = EditSheetState(meditation: meditation)
        XCTAssertFalse(state.hasChanges)

        // When
        state.editedGongSoundId = "clear-strike"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    // MARK: - Applying Changes

    func testEnablingGongAppliesIt() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: false)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedGongEnabled = true

        // Then
        let updated = state.applyChanges()
        XCTAssertTrue(updated.gongEnabled)
    }

    func testDisablingGongAppliesIt() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedGongEnabled = false

        // Then
        let updated = state.applyChanges()
        XCTAssertFalse(updated.gongEnabled)
    }

    func testChangingGongSoundAppliesIt() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedGongSoundId = "classic-bowl"

        // Then
        let updated = state.applyChanges()
        XCTAssertEqual(updated.gongSoundId, "classic-bowl")
    }

    // MARK: - Helpers

    private func makeMeditation(
        gongEnabled: Bool,
        gongSoundId: String = GongSound.defaultSoundId
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation",
            gongEnabled: gongEnabled,
            gongSoundId: gongSoundId
        )
    }
}
