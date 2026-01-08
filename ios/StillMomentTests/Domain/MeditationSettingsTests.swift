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
}
