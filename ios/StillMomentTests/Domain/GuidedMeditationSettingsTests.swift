//
//  GuidedMeditationSettingsTests.swift
//  Still Moment
//
//  Unit tests for GuidedMeditationSettings Value Object
//

import XCTest
@testable import StillMoment

final class GuidedMeditationSettingsTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInit_withNil_createsDisabledSettings() {
        // When
        let settings = GuidedMeditationSettings(preparationTimeSeconds: nil)

        // Then
        XCTAssertNil(settings.preparationTimeSeconds)
    }

    func testInit_withValidValue_preservesValue() {
        // When
        let settings = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // Then
        XCTAssertEqual(settings.preparationTimeSeconds, 15)
    }

    func testInit_default_hasNilPreparationTime() {
        // When
        let settings = GuidedMeditationSettings.default

        // Then
        XCTAssertNil(settings.preparationTimeSeconds)
    }

    // MARK: - Validation Tests

    func testValidatePreparationTime_withNil_returnsNil() {
        // When
        let result = GuidedMeditationSettings.validatePreparationTime(nil)

        // Then
        XCTAssertNil(result)
    }

    func testValidatePreparationTime_withExactValidValue_returnsValue() {
        // When/Then
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(5), 5)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(10), 10)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(15), 15)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(20), 20)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(30), 30)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(45), 45)
    }

    func testValidatePreparationTime_withInvalidValue_returnsClosestValid() {
        // When/Then - values below minimum snap to 5
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(1), 5)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(3), 5)

        // Values between valid options snap to closest
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(7), 5) // closer to 5 than 10
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(8), 10) // closer to 10 than 5
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(12), 10) // closer to 10 than 15
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(13), 15) // closer to 15 than 10
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(25), 20) // closer to 20 than 30
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(26), 30) // closer to 30 than 20
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(37), 30) // closer to 30 than 45
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(38), 45) // closer to 45 than 30

        // Values above maximum snap to 45
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(50), 45)
        XCTAssertEqual(GuidedMeditationSettings.validatePreparationTime(100), 45)
    }

    func testValidatePreparationTime_withZero_snapsToFive() {
        // When
        let result = GuidedMeditationSettings.validatePreparationTime(0)

        // Then
        XCTAssertEqual(result, 5)
    }

    func testValidatePreparationTime_withNegative_snapsToFive() {
        // When
        let result = GuidedMeditationSettings.validatePreparationTime(-10)

        // Then
        XCTAssertEqual(result, 5)
    }

    // MARK: - Immutability Tests

    func testSettings_isImmutable() {
        // Given
        let settings = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // Then - Property is let, not var (compile-time check)
        // This test documents the immutability requirement
        XCTAssertEqual(settings.preparationTimeSeconds, 15)
    }

    // MARK: - Factory Method Tests

    func testWithPreparationTime_createsNewInstance() {
        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // When
        let updated = original.withPreparationTime(30)

        // Then - Original unchanged
        XCTAssertEqual(original.preparationTimeSeconds, 15)
        // New instance has updated value
        XCTAssertEqual(updated.preparationTimeSeconds, 30)
    }

    func testWithPreparationTime_withNil_createsDisabledSettings() {
        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // When
        let updated = original.withPreparationTime(nil)

        // Then
        XCTAssertNil(updated.preparationTimeSeconds)
    }

    func testWithPreparationTime_validatesInput() {
        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // When - Invalid value provided
        let updated = original.withPreparationTime(12)

        // Then - Should be validated to closest (10)
        XCTAssertEqual(updated.preparationTimeSeconds, 10)
    }

    // MARK: - Valid Values Tests

    func testValidPreparationTimeValues_containsExpectedValues() {
        // When
        let values = GuidedMeditationSettings.validPreparationTimeValues

        // Then
        XCTAssertEqual(values, [5, 10, 15, 20, 30, 45])
    }

    func testValidPreparationTimes_includesNilAndAllValues() {
        // When
        let options = GuidedMeditationSettings.validPreparationTimes

        // Then
        XCTAssertEqual(options.count, 7) // nil + 6 values
        XCTAssertNil(options[0])
        XCTAssertEqual(options[1], 5)
        XCTAssertEqual(options[2], 10)
        XCTAssertEqual(options[3], 15)
        XCTAssertEqual(options[4], 20)
        XCTAssertEqual(options[5], 30)
        XCTAssertEqual(options[6], 45)
    }

    // MARK: - Equatable Tests

    func testEquatable_sameValues_areEqual() {
        // Given
        let settings1 = GuidedMeditationSettings(preparationTimeSeconds: 15)
        let settings2 = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // Then
        XCTAssertEqual(settings1, settings2)
    }

    func testEquatable_differentValues_areNotEqual() {
        // Given
        let settings1 = GuidedMeditationSettings(preparationTimeSeconds: 15)
        let settings2 = GuidedMeditationSettings(preparationTimeSeconds: 30)

        // Then
        XCTAssertNotEqual(settings1, settings2)
    }

    func testEquatable_nilVsValue_areNotEqual() {
        // Given
        let settings1 = GuidedMeditationSettings(preparationTimeSeconds: nil)
        let settings2 = GuidedMeditationSettings(preparationTimeSeconds: 15)

        // Then
        XCTAssertNotEqual(settings1, settings2)
    }

    // MARK: - Codable Tests

    func testCodable_encodeDecode_preservesValue() throws {
        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: 20)

        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditationSettings.self, from: encoded)

        // Then
        XCTAssertEqual(decoded, original)
    }

    func testCodable_encodeDecode_preservesNil() throws {
        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: nil)

        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuidedMeditationSettings.self, from: encoded)

        // Then
        XCTAssertEqual(decoded, original)
        XCTAssertNil(decoded.preparationTimeSeconds)
    }
}
