//
//  GuidedMeditationGongTests.swift
//  Still Moment
//
//  Domain Tests - Start/end gong per meditation (shared-106)
//

import XCTest
@testable import StillMoment

final class GuidedMeditationGongTests: XCTestCase {
    // MARK: - Default

    func testGongIsDisabledByDefault() {
        // Given
        let meditation = self.makeMeditation()

        // Then
        XCTAssertFalse(meditation.gongEnabled)
    }

    func testGongSoundDefaultsToStandardGong() {
        // Given
        let meditation = self.makeMeditation()

        // Then: new meditations ring with the standard gong (temple bell)
        XCTAssertEqual(meditation.gongSoundId, GongSound.defaultSoundId)
    }

    // MARK: - Sound Choice (Aenderungsrequest 2026-06-12)

    func testMeditationGongSoundsMatchTimerSoundsWithoutVibration() {
        // Given: the sounds offered for per-meditation selection
        let sounds = GongSound.allMeditationGongSounds

        // Then: same gongs as the timer, but no vibration option
        let timerSoundsWithoutVibration = GongSound.allSounds.filter { $0.id != GongSound.vibrationId }
        XCTAssertEqual(sounds, timerSoundsWithoutVibration)
        XCTAssertFalse(sounds.contains { $0.id == GongSound.vibrationId })
        XCTAssertFalse(sounds.isEmpty)
    }

    // MARK: - Persistence Compatibility

    func testLegacyMeditationWithoutGongFieldDecodesAsDisabled() throws {
        // Given: persisted JSON from a version before the gong setting existed
        let json = """
            {
                "id": "550E8400-E29B-41D4-A716-446655440000",
                "localFilePath": "abc.mp3",
                "fileName": "morning.mp3",
                "duration": 600,
                "teacher": "Test Teacher",
                "name": "Morning Meditation",
                "dateAdded": 700000000
            }
            """

        // When
        let data = try XCTUnwrap(json.data(using: .utf8))
        let meditation = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then: plays without gong, with the standard sound preselected
        XCTAssertFalse(meditation.gongEnabled)
        XCTAssertEqual(meditation.gongSoundId, GongSound.defaultSoundId)
    }

    func testMeditationFromBaseVersionWithoutSoundFieldDecodesAsStandardGong() throws {
        // Given: persisted JSON from the first gong version (no per-meditation sound yet)
        let json = """
            {
                "id": "550E8400-E29B-41D4-A716-446655440000",
                "localFilePath": "abc.mp3",
                "fileName": "morning.mp3",
                "duration": 600,
                "teacher": "Test Teacher",
                "name": "Morning Meditation",
                "dateAdded": 700000000,
                "gongEnabled": true
            }
            """

        // When
        let data = try XCTUnwrap(json.data(using: .utf8))
        let meditation = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then: gong stays enabled and rings with the standard sound
        XCTAssertTrue(meditation.gongEnabled)
        XCTAssertEqual(meditation.gongSoundId, GongSound.defaultSoundId)
    }

    func testGongSettingSurvivesEncodingRoundtrip() throws {
        // Given
        let original = self.makeMeditation(gongEnabled: true, gongSoundId: "deep-resonance")

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then
        XCTAssertTrue(decoded.gongEnabled)
        XCTAssertEqual(decoded.gongSoundId, "deep-resonance")
    }

    func testMigrationToLocalFilePreservesGongSetting() {
        // Given
        let meditation = self.makeMeditation(gongEnabled: true, gongSoundId: "clear-strike")

        // When
        let migrated = meditation.withLocalFilePath("new/path.mp3")

        // Then
        XCTAssertTrue(migrated.gongEnabled)
        XCTAssertEqual(migrated.gongSoundId, "clear-strike")
    }

    // MARK: - Helpers

    private func makeMeditation(
        gongEnabled: Bool = false,
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
