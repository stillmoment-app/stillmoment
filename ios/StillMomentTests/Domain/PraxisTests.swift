//
//  PraxisTests.swift
//  Still Moment
//
//  Tests for Praxis domain model
//

import XCTest
@testable import StillMoment

final class PraxisTests: XCTestCase {
    // MARK: - Default Factory

    func testDefault_hasCorrectDurationMinutes() {
        XCTAssertEqual(Praxis.default.durationMinutes, 10)
    }

    func testDefault_hasCorrectIntervalSettings() {
        let praxis = Praxis.default
        XCTAssertFalse(praxis.intervalGongsEnabled)
        XCTAssertEqual(praxis.intervalMinutes, 5)
        XCTAssertEqual(praxis.intervalMode, .repeating)
        XCTAssertEqual(praxis.intervalSoundId, GongSound.defaultIntervalSoundId)
        XCTAssertEqual(praxis.intervalGongVolume, 0.75, accuracy: 0.001)
    }

    func testDefault_hasCorrectGongSettings() {
        let praxis = Praxis.default
        XCTAssertEqual(praxis.startGongSoundId, GongSound.defaultSoundId)
        XCTAssertEqual(praxis.gongVolume, 1.0, accuracy: 0.001)
    }

    func testDefault_hasCorrectPreparationSettings() {
        let praxis = Praxis.default
        XCTAssertTrue(praxis.preparationTimeEnabled)
        XCTAssertEqual(praxis.preparationTimeSeconds, 15)
    }

    func testDefault_hasSilentBackground() {
        let praxis = Praxis.default
        XCTAssertEqual(praxis.backgroundSoundId, "silent")
        XCTAssertEqual(praxis.backgroundSoundVolume, 0.15, accuracy: 0.001)
    }

    func testDefault_hasNoAttunement() {
        XCTAssertNil(Praxis.default.attunementId)
    }

    func testDefault_hasAttunementDisabled() {
        XCTAssertFalse(Praxis.default.attunementEnabled)
    }

    // MARK: - Immutability (Value Object)

    func testEquality_sameIdSameFields_areEqual() {
        let id = UUID()
        let praxisA = Praxis(id: id, durationMinutes: 10)
        let praxisB = Praxis(id: id, durationMinutes: 10)
        XCTAssertEqual(praxisA, praxisB)
    }

    func testEquality_differentId_areNotEqual() {
        let praxisA = Praxis(id: UUID(), durationMinutes: 10)
        let praxisB = Praxis(id: UUID(), durationMinutes: 10)
        XCTAssertNotEqual(praxisA, praxisB)
    }

    func testEquality_sameIdDifferentDuration_areNotEqual() {
        let id = UUID()
        let praxisA = Praxis(id: id, durationMinutes: 10)
        let praxisB = Praxis(id: id, durationMinutes: 20)
        XCTAssertNotEqual(praxisA, praxisB)
    }

    // MARK: - Validation

    func testValidation_durationBelow1_clampedTo1() {
        let praxis = Praxis(durationMinutes: 0)
        XCTAssertEqual(praxis.durationMinutes, 1)
    }

    func testValidation_durationAbove60_clampedTo60() {
        let praxis = Praxis(durationMinutes: 90)
        XCTAssertEqual(praxis.durationMinutes, 60)
    }

    func testValidation_intervalBelow1_clampedTo1() {
        let praxis = Praxis(intervalMinutes: 0)
        XCTAssertEqual(praxis.intervalMinutes, 1)
    }

    func testValidation_intervalAbove60_clampedTo60() {
        let praxis = Praxis(intervalMinutes: 120)
        XCTAssertEqual(praxis.intervalMinutes, 60)
    }

    func testValidation_volumeBelow0_clampedTo0() {
        let praxis = Praxis(gongVolume: -0.5)
        XCTAssertEqual(praxis.gongVolume, 0.0, accuracy: 0.001)
    }

    func testValidation_volumeAbove1_clampedTo1() {
        let praxis = Praxis(gongVolume: 1.5)
        XCTAssertEqual(praxis.gongVolume, 1.0, accuracy: 0.001)
    }

    func testValidation_invalidPreparationTime_snappedToNearest() {
        // 7 is closest to 5 (distance 2) and 10 (distance 3), so snaps to 5
        let praxis = Praxis(preparationTimeSeconds: 7)
        XCTAssertEqual(praxis.preparationTimeSeconds, 5)
    }

    func testValidation_allVolumesClamped() {
        let praxis = Praxis(
            gongVolume: 2.0,
            intervalGongVolume: -1.0,
            backgroundSoundVolume: 1.5
        )
        XCTAssertEqual(praxis.gongVolume, 1.0, accuracy: 0.001)
        XCTAssertEqual(praxis.intervalGongVolume, 0.0, accuracy: 0.001)
        XCTAssertEqual(praxis.backgroundSoundVolume, 1.0, accuracy: 0.001)
    }

    // MARK: - Migration from MeditationSettings

    func testMigratingFromSettings_preservesDuration() {
        // Given
        let settings = MeditationSettings(durationMinutes: 25)

        // When
        let praxis = Praxis(migratingFrom: settings)

        // Then
        XCTAssertEqual(praxis.durationMinutes, 25)
    }

    func testMigratingFromSettings_preservesAllFields() {
        // Given
        let settings = MeditationSettings(
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            intervalMode: .afterStart,
            intervalSoundId: "temple-bell",
            intervalGongVolume: 0.5,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3,
            durationMinutes: 30,
            preparationTimeEnabled: false,
            preparationTimeSeconds: 10,
            startGongSoundId: "classic-bowl",
            gongVolume: 0.8,
            attunementId: nil
        )

        // When
        let praxis = Praxis(migratingFrom: settings)

        // Then
        XCTAssertEqual(praxis.durationMinutes, 30)
        XCTAssertEqual(praxis.intervalGongsEnabled, true)
        XCTAssertEqual(praxis.intervalMinutes, 10)
        XCTAssertEqual(praxis.intervalMode, .afterStart)
        XCTAssertEqual(praxis.intervalSoundId, "temple-bell")
        XCTAssertEqual(praxis.intervalGongVolume, 0.5, accuracy: 0.001)
        XCTAssertEqual(praxis.backgroundSoundId, "forest")
        XCTAssertEqual(praxis.backgroundSoundVolume, 0.3, accuracy: 0.001)
        XCTAssertFalse(praxis.preparationTimeEnabled)
        XCTAssertEqual(praxis.preparationTimeSeconds, 10)
        XCTAssertEqual(praxis.startGongSoundId, "classic-bowl")
        XCTAssertEqual(praxis.gongVolume, 0.8, accuracy: 0.001)
        XCTAssertNil(praxis.attunementId)
    }

    // MARK: - toMeditationSettings

    func testToMeditationSettings_preservesAllFields() {
        // Given
        let praxis = Praxis(
            id: UUID(),
            durationMinutes: 25,
            preparationTimeEnabled: false,
            preparationTimeSeconds: 10,
            startGongSoundId: "classic-bowl",
            gongVolume: 0.8,
            attunementId: nil,
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            intervalMode: .afterStart,
            intervalSoundId: "temple-bell",
            intervalGongVolume: 0.6,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )

        // When
        let settings = praxis.toMeditationSettings()

        // Then
        XCTAssertEqual(settings.durationMinutes, 25)
        XCTAssertFalse(settings.preparationTimeEnabled)
        XCTAssertEqual(settings.preparationTimeSeconds, 10)
        XCTAssertEqual(settings.startGongSoundId, "classic-bowl")
        XCTAssertEqual(settings.gongVolume, 0.8, accuracy: 0.001)
        XCTAssertNil(settings.attunementId)
        XCTAssertTrue(settings.intervalGongsEnabled)
        XCTAssertEqual(settings.intervalMinutes, 10)
        XCTAssertEqual(settings.intervalMode, .afterStart)
        XCTAssertEqual(settings.intervalSoundId, "temple-bell")
        XCTAssertEqual(settings.intervalGongVolume, 0.6, accuracy: 0.001)
        XCTAssertEqual(settings.backgroundSoundId, "forest")
        XCTAssertEqual(settings.backgroundSoundVolume, 0.3, accuracy: 0.001)
    }

    // MARK: - Builder Methods

    func testWithBackgroundSoundId_replacesId_preservesOtherFields() {
        // Given
        let original = Praxis(durationMinutes: 20, backgroundSoundId: "forest")

        // When
        let updated = original.withBackgroundSoundId("rain")

        // Then
        XCTAssertEqual(updated.backgroundSoundId, "rain")
        XCTAssertEqual(updated.durationMinutes, 20)
        XCTAssertEqual(updated.id, original.id)
    }

    func testWithDurationMinutes_replacesDuration_preservesOtherFields() {
        // Given
        let original = Praxis(durationMinutes: 10, backgroundSoundId: "forest")

        // When
        let updated = original.withDurationMinutes(25)

        // Then
        XCTAssertEqual(updated.durationMinutes, 25)
        XCTAssertEqual(updated.backgroundSoundId, "forest")
        XCTAssertEqual(updated.id, original.id)
    }

    func testWithAttunementId_setsId_preservesOtherFields() {
        // Given
        let original = Praxis(durationMinutes: 15, attunementId: nil)

        // When
        let updated = original.withAttunementId("breath")

        // Then
        XCTAssertEqual(updated.attunementId, "breath")
        XCTAssertEqual(updated.durationMinutes, 15)
        XCTAssertEqual(updated.id, original.id)
    }

    func testWithAttunementEnabled_setsEnabled_preservesOtherFields() {
        // Given
        let original = Praxis(durationMinutes: 15, attunementId: "breath", attunementEnabled: false)

        // When
        let updated = original.withAttunementEnabled(true)

        // Then
        XCTAssertTrue(updated.attunementEnabled)
        XCTAssertEqual(updated.attunementId, "breath")
        XCTAssertEqual(updated.durationMinutes, 15)
        XCTAssertEqual(updated.id, original.id)
    }

    func testWithBackgroundSoundId_preservesAttunementEnabled() {
        // Given
        let original = Praxis(attunementEnabled: true)

        // When
        let updated = original.withBackgroundSoundId("rain")

        // Then
        XCTAssertTrue(updated.attunementEnabled)
    }

    func testWithDurationMinutes_preservesAttunementEnabled() {
        // Given
        let original = Praxis(attunementEnabled: true)

        // When
        let updated = original.withDurationMinutes(25)

        // Then
        XCTAssertTrue(updated.attunementEnabled)
    }

    func testWithAttunementId_preservesAttunementEnabled() {
        // Given
        let original = Praxis(attunementEnabled: true)

        // When
        let updated = original.withAttunementId("breath")

        // Then
        XCTAssertTrue(updated.attunementEnabled)
    }

    // MARK: - Codable Migration

    func testDecode_legacyDataWithoutAttunementEnabled_withAttunementId_defaultsToTrue() throws {
        // Given - Legacy JSON that has attunementId but no attunementEnabled key
        let json = """
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "durationMinutes": 10,
                "preparationTimeEnabled": true,
                "preparationTimeSeconds": 15,
                "startGongSoundId": "temple-bell",
                "gongVolume": 1.0,
                "introductionId": "breath",
                "intervalGongsEnabled": false,
                "intervalMinutes": 5,
                "intervalMode": "repeating",
                "intervalSoundId": "soft-chime",
                "intervalGongVolume": 0.75,
                "backgroundSoundId": "silent",
                "backgroundSoundVolume": 0.15
            }
            """
        let data = Data(json.utf8)

        // When
        let praxis = try JSONDecoder().decode(Praxis.self, from: data)

        // Then - attunementEnabled defaults to true because attunementId is non-nil
        XCTAssertTrue(praxis.attunementEnabled)
        XCTAssertEqual(praxis.attunementId, "breath")
    }

    func testDecode_legacyDataWithoutAttunementEnabled_withoutAttunementId_defaultsToFalse() throws {
        // Given - Legacy JSON without attunementId and without attunementEnabled
        let json = """
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "durationMinutes": 10,
                "preparationTimeEnabled": true,
                "preparationTimeSeconds": 15,
                "startGongSoundId": "temple-bell",
                "gongVolume": 1.0,
                "intervalGongsEnabled": false,
                "intervalMinutes": 5,
                "intervalMode": "repeating",
                "intervalSoundId": "soft-chime",
                "intervalGongVolume": 0.75,
                "backgroundSoundId": "silent",
                "backgroundSoundVolume": 0.15
            }
            """
        let data = Data(json.utf8)

        // When
        let praxis = try JSONDecoder().decode(Praxis.self, from: data)

        // Then - attunementEnabled defaults to false because attunementId is nil
        XCTAssertFalse(praxis.attunementEnabled)
        XCTAssertNil(praxis.attunementId)
    }

    func testDecode_newDataWithAttunementEnabled_preservesValue() throws {
        // Given - New JSON with explicit attunementEnabled
        let json = """
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "durationMinutes": 10,
                "preparationTimeEnabled": true,
                "preparationTimeSeconds": 15,
                "startGongSoundId": "temple-bell",
                "gongVolume": 1.0,
                "introductionId": "breath",
                "introductionEnabled": false,
                "intervalGongsEnabled": false,
                "intervalMinutes": 5,
                "intervalMode": "repeating",
                "intervalSoundId": "soft-chime",
                "intervalGongVolume": 0.75,
                "backgroundSoundId": "silent",
                "backgroundSoundVolume": 0.15
            }
            """
        let data = Data(json.utf8)

        // When
        let praxis = try JSONDecoder().decode(Praxis.self, from: data)

        // Then - attunementEnabled is explicitly false, even though attunementId is set
        XCTAssertFalse(praxis.attunementEnabled)
        XCTAssertEqual(praxis.attunementId, "breath")
    }

    func testEncodeDecode_roundTrip_preservesAttunementEnabled() throws {
        // Given
        let original = Praxis(attunementId: "breath", attunementEnabled: true)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Praxis.self, from: data)

        // Then
        XCTAssertEqual(decoded.attunementEnabled, original.attunementEnabled)
        XCTAssertEqual(decoded.attunementId, original.attunementId)
    }

    // MARK: - Migration preserves attunementEnabled

    func testMigratingFromSettings_preservesAttunementEnabled() {
        // Given
        let settings = MeditationSettings(attunementId: "breath", attunementEnabled: true)

        // When
        let praxis = Praxis(migratingFrom: settings)

        // Then
        XCTAssertTrue(praxis.attunementEnabled)
        XCTAssertEqual(praxis.attunementId, "breath")
    }

    func testToMeditationSettings_preservesAttunementEnabled() {
        // Given
        let praxis = Praxis(attunementId: "breath", attunementEnabled: true)

        // When
        let settings = praxis.toMeditationSettings()

        // Then
        XCTAssertTrue(settings.attunementEnabled)
    }
}
