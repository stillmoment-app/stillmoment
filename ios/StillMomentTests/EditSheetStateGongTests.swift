//
//  EditSheetStateGongTests.swift
//  Still Moment
//
//  Domain Tests - Gong settings in the edit sheet (shared-106)
//

import XCTest
@testable import StillMoment

final class EditSheetStateGongTests: XCTestCase {
    // MARK: - Prefill

    func testGongTogglesPrefilledFromMeditation() {
        // Given: only the start gong is enabled
        let meditation = self.makeMeditation(startGongEnabled: true, endGongEnabled: false)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertTrue(state.editedStartGongEnabled)
        XCTAssertFalse(state.editedEndGongEnabled)
    }

    func testGongTogglesOffWhenMeditationHasNoGongs() {
        // Given
        let meditation = self.makeMeditation()

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertFalse(state.editedStartGongEnabled)
        XCTAssertFalse(state.editedEndGongEnabled)
    }

    func testGongSoundPrefilledFromMeditation() {
        // Given
        let meditation = self.makeMeditation(startGongEnabled: true, gongSoundId: "deep-resonance")

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedGongSoundId, "deep-resonance")
    }

    // MARK: - Change Detection

    func testTogglingStartGongCountsAsChange() {
        // Given
        let meditation = self.makeMeditation()
        var state = EditSheetState(meditation: meditation)
        XCTAssertFalse(state.hasChanges)

        // When
        state.editedStartGongEnabled = true

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testTogglingEndGongCountsAsChange() {
        // Given
        let meditation = self.makeMeditation()
        var state = EditSheetState(meditation: meditation)
        XCTAssertFalse(state.hasChanges)

        // When
        state.editedEndGongEnabled = true

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testTogglingGongBackIsNoChange() {
        // Given
        let meditation = self.makeMeditation(startGongEnabled: true, endGongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedStartGongEnabled = false
        state.editedStartGongEnabled = true

        // Then
        XCTAssertFalse(state.hasChanges)
    }

    func testChangingGongSoundCountsAsChange() {
        // Given
        let meditation = self.makeMeditation(startGongEnabled: true)
        var state = EditSheetState(meditation: meditation)
        XCTAssertFalse(state.hasChanges)

        // When
        state.editedGongSoundId = "clear-strike"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    // MARK: - Applying Changes

    func testEnablingGongsIndependentlyAppliesThem() {
        // Given: the user enables only the end gong
        let meditation = self.makeMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedEndGongEnabled = true

        // Then
        let updated = state.applyChanges()
        XCTAssertFalse(updated.startGongEnabled)
        XCTAssertTrue(updated.endGongEnabled)
    }

    func testDisablingGongAppliesIt() {
        // Given
        let meditation = self.makeMeditation(startGongEnabled: true, endGongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedStartGongEnabled = false

        // Then
        let updated = state.applyChanges()
        XCTAssertFalse(updated.startGongEnabled)
        XCTAssertTrue(updated.endGongEnabled)
    }

    func testChangingGongSoundAppliesIt() {
        // Given
        let meditation = self.makeMeditation(startGongEnabled: true)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedGongSoundId = "classic-bowl"

        // Then
        let updated = state.applyChanges()
        XCTAssertEqual(updated.gongSoundId, "classic-bowl")
    }

    // MARK: - Helpers

    private func makeMeditation(
        startGongEnabled: Bool = false,
        endGongEnabled: Bool = false,
        gongSoundId: String = GongSound.defaultSoundId
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation",
            startGongEnabled: startGongEnabled,
            endGongEnabled: endGongEnabled,
            gongSoundId: gongSoundId
        )
    }
}
