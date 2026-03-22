//
//  MeditationSettingsTests+Attunement.swift
//  Still Moment
//
//  Tests for attunement-related MeditationSettings validation
//

import XCTest
@testable import StillMoment

extension MeditationSettingsTests {
    // MARK: - Minimum Duration with Attunement

    func testMinimumDuration_noAttunement_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil), 1)
    }

    func testMinimumDuration_unknownAttunement_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "nonexistent"), 1)
    }

    func testMinimumDuration_breathAttunement_enabled_isTwoMinutes() {
        // Breath attunement is 95 seconds (1:35)
        // ceil(95/60) = 2 minutes
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", attunementEnabled: true), 2)
    }

    func testMinimumDurationMinutes_computedProperty() {
        let settings = MeditationSettings(attunementId: "breath", attunementEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 2)

        let settingsNoAttunement = MeditationSettings(attunementId: nil)
        XCTAssertEqual(settingsNoAttunement.minimumDurationMinutes, 1)
    }

    func testValidateDuration_withAttunementEnabled_clampsToMinimum() {
        // With breath attunement enabled, minimum is 2 (ceil(95/60) = 2)
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, attunementId: "breath", attunementEnabled: true),
            2
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(2, attunementId: "breath", attunementEnabled: true),
            2
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(3, attunementId: "breath", attunementEnabled: true),
            3
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(10, attunementId: "breath", attunementEnabled: true),
            10
        )
    }

    func testValidateDuration_withoutAttunement_clampsToOne() {
        XCTAssertEqual(MeditationSettings.validateDuration(0, attunementId: nil), 1)
        XCTAssertEqual(MeditationSettings.validateDuration(1, attunementId: nil), 1)
        XCTAssertEqual(MeditationSettings.validateDuration(10, attunementId: nil), 10)
    }

    func testInit_withAttunementEnabled_clampsLowDuration() {
        // Given - Duration below minimum for breath attunement when enabled
        let settings = MeditationSettings(
            durationMinutes: 1,
            attunementId: "breath",
            attunementEnabled: true
        )

        // Then - Duration is clamped to minimum (2 minutes, ceil(95/60))
        XCTAssertEqual(settings.durationMinutes, 2)
    }

    func testInit_withAttunementEnabled_preservesValidDuration() {
        // Given - Duration above minimum
        let settings = MeditationSettings(
            durationMinutes: 10,
            attunementId: "breath",
            attunementEnabled: true
        )

        // Then - Duration preserved
        XCTAssertEqual(settings.durationMinutes, 10)
    }

    func testInit_withAttunementDisabled_doesNotClampDuration() {
        // Given - Attunement disabled, so no duration clamping
        let settings = MeditationSettings(
            durationMinutes: 1,
            attunementId: "breath",
            attunementEnabled: false
        )

        // Then - Duration stays at 1
        XCTAssertEqual(settings.durationMinutes, 1)
    }

    // MARK: - Minimum Duration with attunementEnabled

    func testMinimumDuration_attunementDisabled_isOne() {
        // Even with a valid attunementId, if attunementEnabled is false, minimum is 1
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", attunementEnabled: false), 1)
    }

    func testMinimumDuration_attunementEnabled_returnsAttunementBased() {
        // With attunementEnabled true and valid attunementId, minimum is attunement-based
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", attunementEnabled: true), 2)
    }

    func testMinimumDuration_attunementEnabledNoId_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil, attunementEnabled: true), 1)
    }

    func testMinimumDurationMinutes_attunementDisabled_isOne() {
        let settings = MeditationSettings(attunementId: "breath", attunementEnabled: false)
        XCTAssertEqual(settings.minimumDurationMinutes, 1)
    }

    func testMinimumDurationMinutes_attunementEnabled_isTwo() {
        let settings = MeditationSettings(attunementId: "breath", attunementEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 2)
    }

    func testValidateDuration_attunementDisabled_clampsToOne() {
        // With attunementEnabled false, even with attunementId, minimum is 1
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, attunementId: "breath", attunementEnabled: false),
            1
        )
    }

    func testValidateDuration_attunementEnabled_clampsToMinimum() {
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, attunementId: "breath", attunementEnabled: true),
            2
        )
    }

    // MARK: - Custom Attunement Duration

    func testMinimumDuration_customAttunementDuration_331seconds_isSixMinutes() {
        // Custom attunement of 5:31 (331s) → ceil(331/60) = 6
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeAttunementId: "custom-uuid",
                attunementDurationSeconds: 331
            ),
            6
        )
    }

    func testMinimumDuration_customAttunementDuration_61seconds_isTwoMinutes() {
        // Just over 60s → ceil(61/60) = 2
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeAttunementId: "custom-uuid",
                attunementDurationSeconds: 61
            ),
            2
        )
    }

    func testMinimumDuration_customAttunementDuration_nilId_isOne() {
        // Even with duration provided, nil ID means no attunement active → 1
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeAttunementId: nil,
                attunementDurationSeconds: 331
            ),
            1
        )
    }

    func testValidateDuration_customAttunementDuration_clampsToMinimum() {
        // 331s attunement → minimum 6, selecting 3 should clamp to 6
        XCTAssertEqual(
            MeditationSettings.validateDuration(
                3,
                attunementId: "custom-uuid",
                attunementEnabled: true,
                attunementDurationSeconds: 331
            ),
            6
        )
    }

    func testMinimumDuration_builtInBreath_noExtraMinute() {
        // Breath attunement is 95s → ceil(95/60) = 2 (not 3)
        XCTAssertEqual(
            MeditationSettings.minimumDuration(for: "breath", attunementEnabled: true),
            2
        )
    }

    // MARK: - minimumDurationMinutes with customAttunementDurationSeconds Property

    func testMinimumDurationMinutes_withCustomAttunementDurationProperty_returnsCorrectMinimum() {
        // Custom attunement of 5:31 (331s) → ceil(331/60) = 6
        let settings = MeditationSettings(
            attunementId: "custom-uuid",
            attunementEnabled: true,
            customAttunementDurationSeconds: 331
        )
        XCTAssertEqual(settings.minimumDurationMinutes, 6)
    }

    func testMinimumDurationMinutes_withNilCustomAttunementDuration_usesBuiltIn() {
        let settings = MeditationSettings(
            attunementId: "breath",
            attunementEnabled: true,
            customAttunementDurationSeconds: nil
        )
        XCTAssertEqual(settings.minimumDurationMinutes, 2)
    }

    func testInit_withCustomAttunementDuration_clampsDurationToMinimum() {
        // 331s → minimum 6, duration 3 should clamp to 6
        let settings = MeditationSettings(
            durationMinutes: 3,
            attunementId: "custom-uuid",
            attunementEnabled: true,
            customAttunementDurationSeconds: 331
        )
        XCTAssertEqual(settings.durationMinutes, 6)
    }
}
