//
//  GuidedMeditationGongTests.swift
//  Still Moment
//
//  Domain Tests - Start/end gong per meditation (shared-106)
//

import XCTest
@testable import StillMoment

final class GuidedMeditationGongTests: XCTestCase {
    // MARK: - Defaults

    func testGongsAreDisabledByDefault() {
        // Given
        let meditation = self.makeMeditation()

        // Then
        XCTAssertFalse(meditation.startGongEnabled)
        XCTAssertFalse(meditation.endGongEnabled)
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

    func testLegacyMeditationWithoutGongFieldsDecodesAsDisabled() throws {
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

        // Then: plays without gongs, with the standard sound preselected
        XCTAssertFalse(meditation.startGongEnabled)
        XCTAssertFalse(meditation.endGongEnabled)
        XCTAssertEqual(meditation.gongSoundId, GongSound.defaultSoundId)
    }

    func testMeditationWithLegacyCombinedGongFlagDecodesWithBothGongsEnabled() throws {
        // Given: persisted JSON from the version with a single combined gong toggle
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

        // Then: the combined setting carries over to both gongs
        XCTAssertTrue(meditation.startGongEnabled)
        XCTAssertTrue(meditation.endGongEnabled)
        XCTAssertEqual(meditation.gongSoundId, GongSound.defaultSoundId)
    }

    func testGongSettingsSurviveEncodingRoundtrip() throws {
        // Given: only the end gong is enabled, with a custom sound
        let original = self.makeMeditation(
            startGongEnabled: false,
            endGongEnabled: true,
            gongSoundId: "deep-resonance"
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditation.self, from: data)

        // Then
        XCTAssertFalse(decoded.startGongEnabled)
        XCTAssertTrue(decoded.endGongEnabled)
        XCTAssertEqual(decoded.gongSoundId, "deep-resonance")
    }

    func testMigrationToLocalFilePreservesGongSettings() {
        // Given
        let meditation = self.makeMeditation(
            startGongEnabled: true,
            endGongEnabled: false,
            gongSoundId: "clear-strike"
        )

        // When
        let migrated = meditation.withLocalFilePath("new/path.mp3")

        // Then
        XCTAssertTrue(migrated.startGongEnabled)
        XCTAssertFalse(migrated.endGongEnabled)
        XCTAssertEqual(migrated.gongSoundId, "clear-strike")
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
