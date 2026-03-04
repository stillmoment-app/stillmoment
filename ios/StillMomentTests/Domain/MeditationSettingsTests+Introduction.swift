//
//  MeditationSettingsTests+Introduction.swift
//  Still Moment
//
//  Tests for introduction-related MeditationSettings validation
//

import XCTest
@testable import StillMoment

extension MeditationSettingsTests {
    // MARK: - Minimum Duration with Introduction

    func testMinimumDuration_noIntroduction_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil), 1)
    }

    func testMinimumDuration_unknownIntroduction_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "nonexistent"), 1)
    }

    func testMinimumDuration_breathIntroduction_enabled_isTwoMinutes() {
        // Breath introduction is 95 seconds (1:35)
        // ceil(95/60) = 2 minutes
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: true), 2)
    }

    func testMinimumDurationMinutes_computedProperty() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 2)

        let settingsNoIntro = MeditationSettings(introductionId: nil)
        XCTAssertEqual(settingsNoIntro.minimumDurationMinutes, 1)
    }

    func testValidateDuration_withIntroductionEnabled_clampsToMinimum() {
        // With breath introduction enabled, minimum is 2 (ceil(95/60) = 2)
        XCTAssertEqual(
            MeditationSettings.validateDuration(1, introductionId: "breath", introductionEnabled: true),
            2
        )
        XCTAssertEqual(
            MeditationSettings.validateDuration(2, introductionId: "breath", introductionEnabled: true),
            2
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

        // Then - Duration is clamped to minimum (2 minutes, ceil(95/60))
        XCTAssertEqual(settings.durationMinutes, 2)
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

    // MARK: - Minimum Duration with introductionEnabled

    func testMinimumDuration_introductionDisabled_isOne() {
        // Even with a valid introductionId, if introductionEnabled is false, minimum is 1
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: false), 1)
    }

    func testMinimumDuration_introductionEnabled_returnsIntroBased() {
        // With introductionEnabled true and valid introductionId, minimum is intro-based
        XCTAssertEqual(MeditationSettings.minimumDuration(for: "breath", introductionEnabled: true), 2)
    }

    func testMinimumDuration_introductionEnabledNoId_isOne() {
        XCTAssertEqual(MeditationSettings.minimumDuration(for: nil, introductionEnabled: true), 1)
    }

    func testMinimumDurationMinutes_introductionDisabled_isOne() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: false)
        XCTAssertEqual(settings.minimumDurationMinutes, 1)
    }

    func testMinimumDurationMinutes_introductionEnabled_isTwo() {
        let settings = MeditationSettings(introductionId: "breath", introductionEnabled: true)
        XCTAssertEqual(settings.minimumDurationMinutes, 2)
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
            2
        )
    }

    // MARK: - Custom Attunement Duration

    func testMinimumDuration_customIntroDuration_331seconds_isSixMinutes() {
        // Custom attunement of 5:31 (331s) → ceil(331/60) = 6
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeIntroductionId: "custom-uuid",
                customIntroDurationSeconds: 331
            ),
            6
        )
    }

    func testMinimumDuration_customIntroDuration_61seconds_isTwoMinutes() {
        // Just over 60s → ceil(61/60) = 2
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeIntroductionId: "custom-uuid",
                customIntroDurationSeconds: 61
            ),
            2
        )
    }

    func testMinimumDuration_customIntroDuration_nilId_isOne() {
        // Even with duration provided, nil ID means no introduction active → 1
        XCTAssertEqual(
            MeditationSettings.minimumDuration(
                activeIntroductionId: nil,
                customIntroDurationSeconds: 331
            ),
            1
        )
    }

    func testValidateDuration_customIntroDuration_clampsToMinimum() {
        // 331s intro → minimum 6, selecting 3 should clamp to 6
        XCTAssertEqual(
            MeditationSettings.validateDuration(
                3,
                introductionId: "custom-uuid",
                introductionEnabled: true,
                customIntroDurationSeconds: 331
            ),
            6
        )
    }

    func testMinimumDuration_builtInBreath_noExtraMinute() {
        // Breath introduction is 95s → ceil(95/60) = 2 (not 3)
        XCTAssertEqual(
            MeditationSettings.minimumDuration(for: "breath", introductionEnabled: true),
            2
        )
    }

    // MARK: - minimumDurationMinutes with customIntroDurationSeconds Property

    func testMinimumDurationMinutes_withCustomIntroDurationProperty_returnsCorrectMinimum() {
        // Custom attunement of 5:31 (331s) → ceil(331/60) = 6
        let settings = MeditationSettings(
            introductionId: "custom-uuid",
            introductionEnabled: true,
            customIntroDurationSeconds: 331
        )
        XCTAssertEqual(settings.minimumDurationMinutes, 6)
    }

    func testMinimumDurationMinutes_withNilCustomIntroDuration_usesBuiltIn() {
        let settings = MeditationSettings(
            introductionId: "breath",
            introductionEnabled: true,
            customIntroDurationSeconds: nil
        )
        XCTAssertEqual(settings.minimumDurationMinutes, 2)
    }

    func testInit_withCustomIntroDuration_clampsDurationToMinimum() {
        // 331s → minimum 6, duration 3 should clamp to 6
        let settings = MeditationSettings(
            durationMinutes: 3,
            introductionId: "custom-uuid",
            introductionEnabled: true,
            customIntroDurationSeconds: 331
        )
        XCTAssertEqual(settings.durationMinutes, 6)
    }
}
