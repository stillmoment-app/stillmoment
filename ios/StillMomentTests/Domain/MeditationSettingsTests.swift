//
//  MeditationSettingsTests.swift
//  Still Moment
//
//  Tests for MeditationSettings domain model
//

import XCTest
@testable import StillMoment

final class MeditationSettingsTests: XCTestCase {
    // MARK: - Preparation Time Validation

    func testValidatePreparationTime_validValues_returnsUnchanged() {
        // Valid values should pass through unchanged
        XCTAssertEqual(MeditationSettings.validatePreparationTime(5), 5)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(10), 10)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(15), 15)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(20), 20)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(30), 30)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(45), 45)
    }

    func testValidatePreparationTime_invalidValue_returnsClosest() {
        // Values between valid options should snap to closest
        XCTAssertEqual(MeditationSettings.validatePreparationTime(7), 5) // Closer to 5 than 10
        XCTAssertEqual(MeditationSettings.validatePreparationTime(8), 10) // Closer to 10 than 5
        XCTAssertEqual(MeditationSettings.validatePreparationTime(12), 10) // Closer to 10 than 15
        XCTAssertEqual(MeditationSettings.validatePreparationTime(13), 15) // Closer to 15 than 10
        XCTAssertEqual(MeditationSettings.validatePreparationTime(25), 20) // Closer to 20 than 30
        XCTAssertEqual(MeditationSettings.validatePreparationTime(35), 30) // Closer to 30 than 45
        XCTAssertEqual(MeditationSettings.validatePreparationTime(40), 45) // Closer to 45 than 30
    }

    func testValidatePreparationTime_extremeValues_returnsClosestBoundary() {
        // Very low values should return minimum (5)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(0), 5)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(1), 5)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(-10), 5)

        // Very high values should return maximum (45)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(50), 45)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(100), 45)
        XCTAssertEqual(MeditationSettings.validatePreparationTime(1000), 45)
    }

    // MARK: - Initialization with Validation

    func testInit_appliesPreparationTimeValidation() {
        // Given - Invalid preparation time
        let settings = MeditationSettings(
            preparationTimeEnabled: true,
            preparationTimeSeconds: 7 // Invalid - should become 5
        )

        // Then - Should be validated to closest valid value
        XCTAssertEqual(settings.preparationTimeSeconds, 5)
    }

    // MARK: - Default Settings

    func testDefault_hasCorrectPreparationSettings() {
        let settings = MeditationSettings.default

        XCTAssertTrue(settings.preparationTimeEnabled)
        XCTAssertEqual(settings.preparationTimeSeconds, 15)
    }

    // MARK: - Valid Preparation Times Array

    func testValidPreparationTimes_containsExpectedValues() {
        let expected = [5, 10, 15, 20, 30, 45]
        XCTAssertEqual(MeditationSettings.validPreparationTimes, expected)
    }

    // MARK: - Gong Sound Settings

    func testDefault_hasCorrectGongSoundSettings() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.startGongSoundId, GongSound.defaultSoundId)
    }

    func testInit_defaultGongSoundId() {
        let settings = MeditationSettings()

        XCTAssertEqual(settings.startGongSoundId, "temple-bell")
    }

    func testInit_customGongSoundId() {
        let settings = MeditationSettings(startGongSoundId: "classic-bowl")

        XCTAssertEqual(settings.startGongSoundId, "classic-bowl")
    }

    func testKeys_containsGongSoundKey() {
        XCTAssertEqual(MeditationSettings.Keys.startGongSoundId, "startGongSoundId")
    }

    func testKeys_containsGongVolumeKey() {
        XCTAssertEqual(MeditationSettings.Keys.gongVolume, "gongVolume")
    }

    // MARK: - Gong Volume Settings

    func testDefault_hasCorrectGongVolume() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.gongVolume, 1.0)
    }

    func testInit_defaultGongVolume() {
        let settings = MeditationSettings()

        XCTAssertEqual(settings.gongVolume, 1.0)
    }

    func testInit_customGongVolume() {
        let settings = MeditationSettings(gongVolume: 0.5)

        XCTAssertEqual(settings.gongVolume, 0.5, accuracy: 0.01)
    }

    func testValidateVolume_clampsToRange() {
        // Below minimum
        XCTAssertEqual(MeditationSettings.validateVolume(-0.5), 0.0)

        // Above maximum
        XCTAssertEqual(MeditationSettings.validateVolume(1.5), 1.0)

        // Within range
        XCTAssertEqual(MeditationSettings.validateVolume(0.5), 0.5)
    }

    func testInit_validatesGongVolume() {
        // Given - Invalid gong volume
        let settings = MeditationSettings(gongVolume: 1.5)

        // Then - Should be clamped to 1.0
        XCTAssertEqual(settings.gongVolume, 1.0)
    }

    func testEquatable_differentGongVolumes_areNotEqual() {
        let settings1 = MeditationSettings(gongVolume: 0.5)
        let settings2 = MeditationSettings(gongVolume: 0.8)

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesGongVolume() throws {
        let original = MeditationSettings(gongVolume: 0.75)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertEqual(decoded.gongVolume, 0.75, accuracy: 0.01)
    }

    // MARK: - Interval Gong Volume Settings

    func testDefault_hasCorrectIntervalGongVolume() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.intervalGongVolume, 0.75, accuracy: 0.01)
    }

    func testDefaultIntervalGongVolume_isPointSevenFive() {
        XCTAssertEqual(MeditationSettings.defaultIntervalGongVolume, 0.75, accuracy: 0.001)
    }

    func testInit_defaultIntervalGongVolume() {
        let settings = MeditationSettings()

        XCTAssertEqual(settings.intervalGongVolume, 0.75, accuracy: 0.001)
    }

    func testInit_customIntervalGongVolume() {
        let settings = MeditationSettings(intervalGongVolume: 0.5)

        XCTAssertEqual(settings.intervalGongVolume, 0.5, accuracy: 0.001)
    }

    func testInit_validatesIntervalGongVolume() {
        let settingsAboveMax = MeditationSettings(intervalGongVolume: 1.5)
        XCTAssertEqual(settingsAboveMax.intervalGongVolume, 1.0, accuracy: 0.001)

        let settingsBelowMin = MeditationSettings(intervalGongVolume: -0.5)
        XCTAssertEqual(settingsBelowMin.intervalGongVolume, 0.0, accuracy: 0.001)
    }

    func testKeys_containsIntervalGongVolumeKey() {
        XCTAssertEqual(MeditationSettings.Keys.intervalGongVolume, "intervalGongVolume")
    }

    func testEquatable_differentIntervalGongVolumes_areNotEqual() {
        let settings1 = MeditationSettings(intervalGongVolume: 0.3)
        let settings2 = MeditationSettings(intervalGongVolume: 0.8)

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesIntervalGongVolume() throws {
        let original = MeditationSettings(intervalGongVolume: 0.6)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertEqual(decoded.intervalGongVolume, 0.6, accuracy: 0.001)
    }

    func testEquatable_differentGongSoundIds_areNotEqual() {
        let settings1 = MeditationSettings(startGongSoundId: "classic-bowl")
        let settings2 = MeditationSettings(startGongSoundId: "clear-strike")

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesGongSoundId() throws {
        let original = MeditationSettings(startGongSoundId: "clear-strike")

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertEqual(decoded.startGongSoundId, "clear-strike")
    }

    // MARK: - Background Sound Volume Settings

    func testDefault_hasCorrectBackgroundSoundVolume() {
        let settings = MeditationSettings.default

        XCTAssertEqual(settings.backgroundSoundVolume, MeditationSettings.defaultBackgroundSoundVolume)
    }

    func testDefaultBackgroundSoundVolume_isPointOneFive() {
        XCTAssertEqual(MeditationSettings.defaultBackgroundSoundVolume, 0.15, accuracy: 0.001)
    }

    func testInit_defaultBackgroundSoundVolume() {
        let settings = MeditationSettings()

        XCTAssertEqual(settings.backgroundSoundVolume, 0.15, accuracy: 0.001)
    }

    func testInit_customBackgroundSoundVolume() {
        let settings = MeditationSettings(backgroundSoundVolume: 0.5)

        XCTAssertEqual(settings.backgroundSoundVolume, 0.5, accuracy: 0.001)
    }

    func testInit_validatesBackgroundSoundVolume() {
        let settingsAboveMax = MeditationSettings(backgroundSoundVolume: 1.5)
        XCTAssertEqual(settingsAboveMax.backgroundSoundVolume, 1.0, accuracy: 0.001)

        let settingsBelowMin = MeditationSettings(backgroundSoundVolume: -0.5)
        XCTAssertEqual(settingsBelowMin.backgroundSoundVolume, 0.0, accuracy: 0.001)
    }

    func testKeys_containsBackgroundSoundVolumeKey() {
        XCTAssertEqual(MeditationSettings.Keys.backgroundSoundVolume, "backgroundSoundVolume")
    }

    func testEquatable_differentBackgroundSoundVolumes_areNotEqual() {
        let settings1 = MeditationSettings(backgroundSoundVolume: 0.3)
        let settings2 = MeditationSettings(backgroundSoundVolume: 0.7)

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesBackgroundSoundVolume() throws {
        let original = MeditationSettings(backgroundSoundVolume: 0.75)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertEqual(decoded.backgroundSoundVolume, 0.75, accuracy: 0.001)
    }
}
