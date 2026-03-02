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

    // MARK: - Introduction Settings

    func testDefault_hasNoIntroduction() {
        let settings = MeditationSettings.default

        XCTAssertNil(settings.introductionId)
    }

    func testInit_defaultIntroductionId() {
        let settings = MeditationSettings()

        XCTAssertNil(settings.introductionId)
    }

    func testInit_customIntroductionId() {
        let settings = MeditationSettings(introductionId: "breath")

        XCTAssertEqual(settings.introductionId, "breath")
    }

    func testKeys_containsIntroductionIdKey() {
        XCTAssertEqual(MeditationSettings.Keys.introductionId, "introductionId")
    }

    func testEquatable_differentIntroductionIds_areNotEqual() {
        let settings1 = MeditationSettings(introductionId: nil)
        let settings2 = MeditationSettings(introductionId: "breath")

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesIntroductionId() throws {
        let original = MeditationSettings(introductionId: "breath")

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertEqual(decoded.introductionId, "breath")
    }

    func testCodable_encodesAndDecodesNilIntroductionId() throws {
        let original = MeditationSettings(introductionId: nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertNil(decoded.introductionId)
    }

    // MARK: - Minimum Duration with Introduction

    func testMinimumDuration_noIntroduction_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil), 1)
    }

    func testMinimumDuration_unknownIntroduction_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "nonexistent"), 1)
    }

    func testMinimumDuration_breathIntroduction_enabled_isThreeMinutes() {
        // Breath introduction is 95 seconds (1:35)
        // ceil(95/60) + 1 = 2 + 1 = 3 minutes
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: true), 3)
    }

    func testMinimumDurationMinutes_computedProperty() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 3)

        let settingsNoIntro = MeditationSettings(introductionId: nil)
        XCTAssertEqual(settingsNoIntro.minimumDurationMinutes, 1)
    }

    func testValidateDuration_withIntroductionEnabled_clampsToMinimum() {
        // With breath introduction enabled, minimum is 3
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, introductionId: "breath", introductionEnabled: true),
            3
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(2, introductionId: "breath", introductionEnabled: true),
            3
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(3, introductionId: "breath", introductionEnabled: true),
            3
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(10, introductionId: "breath", introductionEnabled: true),
            10
        )
    }

    func testValidateDuration_withoutIntroduction_clampsToOne() {
        XCTAssertEqual(MeditationSettings.validateDuration(0, introductionId: nil), 1)
        XCTAssertEqual(MeditationSettings.validateDuration(1, introductionId: nil), 1)
        XCTAssertEqual(MeditationSettings.validateDuration(10, introductionId: nil), 10)
    }

    func testInit_withIntroductionEnabled_clampsLowDuration() {
        // Given - Duration below minimum for breath introduction when enabled
        let settings = MeditationSettings(
            durationMinutes: 1,
            introductionId: "breath",
            introductionEnabled: true
        )

        // Then - Duration is clamped to minimum (3 minutes)
        XCTAssertEqual(settings.durationMinutes, 3)
    }

    func testInit_withIntroductionEnabled_preservesValidDuration() {
        // Given - Duration above minimum
        let settings = MeditationSettings(
            durationMinutes: 10,
            introductionId: "breath",
            introductionEnabled: true
        )

        // Then - Duration preserved
        XCTAssertEqual(settings.durationMinutes, 10)
    }

    func testInit_withIntroductionDisabled_doesNotClampDuration() {
        // Given - Introduction disabled, so no duration clamping
        let settings = MeditationSettings(
            durationMinutes: 1,
            introductionId: "breath",
            introductionEnabled: false
        )

        // Then - Duration stays at 1
        XCTAssertEqual(settings.durationMinutes, 1)
    }

    // MARK: - Introduction Enabled Settings

    func testDefault_hasIntroductionDisabled() {
        let settings = MeditationSettings.default

        XCTAssertFalse(settings.introductionEnabled)
    }

    func testInit_defaultIntroductionEnabled() {
        let settings = MeditationSettings()

        XCTAssertFalse(settings.introductionEnabled)
    }

    func testInit_customIntroductionEnabled() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: true)

        XCTAssertTrue(settings.introductionEnabled)
    }

    func testKeys_containsIntroductionEnabledKey() {
        XCTAssertEqual(MeditationSettings.Keys.introductionEnabled, "introductionEnabled")
    }

    func testEquatable_differentIntroductionEnabled_areNotEqual() {
        let settings1 = MeditationSettings(introductionId: "breath", introductionEnabled: false)
        let settings2 = MeditationSettings(introductionId: "breath", introductionEnabled: true)

        XCTAssertNotEqual(settings1, settings2)
    }

    func testCodable_encodesAndDecodesIntroductionEnabled() throws {
        let original = MeditationSettings(introductionId: "breath", introductionEnabled: true)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MeditationSettings.self, from: data)

        XCTAssertTrue(decoded.introductionEnabled)
    }

    // MARK: - Minimum Duration with introductionEnabled

    func testMinimumDuration_introductionDisabled_isOne() {
        // Even with a valid introductionId, if introductionEnabled is false, minimum is 1
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: false), 1)
    }

    func testMinimumDuration_introductionEnabled_returnsIntroBased() {
        // With introductionEnabled true and valid introductionId, minimum is intro-based
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: true), 3)
    }

    func testMinimumDuration_introductionEnabledNoId_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil, introductionEnabled: true), 1)
    }

    func testMinimumDurationMinutes_introductionDisabled_isOne() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: false)
        XCTAssertEqual(settings.minimumDurationMinutes, 1)
    }

    func testMinimumDurationMinutes_introductionEnabled_isThree() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 3)
    }

    func testValidateDuration_introductionDisabled_clampsToOne() {
        // With introductionEnabled false, even with introductionId, minimum is 1
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, introductionId: "breath", introductionEnabled: false),
            1
        )
    }

    func testValidateDuration_introductionEnabled_clampsToMinimum() {
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, introductionId: "breath", introductionEnabled: true),
            3
        )
    }
}
