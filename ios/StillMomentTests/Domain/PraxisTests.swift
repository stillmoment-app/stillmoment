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

    func testDefault_hasNoIntroduction() {
        XCTAssertNil(Praxis.default.introductionId)
    }

    // MARK: - Immutability (Value Object)

    func testEquality_sameIdSameFields_areEqual() {
        let id = UUID()
        let praxisA = Praxis(id: id, name: "Test", durationMinutes: 10)
        let praxisB = Praxis(id: id, name: "Test", durationMinutes: 10)
        XCTAssertEqual(praxisA, praxisB)
    }

    func testEquality_differentId_areNotEqual() {
        let praxisA = Praxis(id: UUID(), name: "Test", durationMinutes: 10)
        let praxisB = Praxis(id: UUID(), name: "Test", durationMinutes: 10)
        XCTAssertNotEqual(praxisA, praxisB)
    }

    func testEquality_sameIdDifferentName_areNotEqual() {
        let id = UUID()
        let praxisA = Praxis(id: id, name: "Morning", durationMinutes: 10)
        let praxisB = Praxis(id: id, name: "Evening", durationMinutes: 10)
        XCTAssertNotEqual(praxisA, praxisB)
    }

    // MARK: - Validation

    func testValidation_durationBelow1_clampedTo1() {
        let praxis = Praxis(name: "Test", durationMinutes: 0)
        XCTAssertEqual(praxis.durationMinutes, 1)
    }

    func testValidation_durationAbove60_clampedTo60() {
        let praxis = Praxis(name: "Test", durationMinutes: 90)
        XCTAssertEqual(praxis.durationMinutes, 60)
    }

    func testValidation_intervalBelow1_clampedTo1() {
        let praxis = Praxis(name: "Test", intervalMinutes: 0)
        XCTAssertEqual(praxis.intervalMinutes, 1)
    }

    func testValidation_intervalAbove60_clampedTo60() {
        let praxis = Praxis(name: "Test", intervalMinutes: 120)
        XCTAssertEqual(praxis.intervalMinutes, 60)
    }

    func testValidation_volumeBelow0_clampedTo0() {
        let praxis = Praxis(name: "Test", gongVolume: -0.5)
        XCTAssertEqual(praxis.gongVolume, 0.0, accuracy: 0.001)
    }

    func testValidation_volumeAbove1_clampedTo1() {
        let praxis = Praxis(name: "Test", gongVolume: 1.5)
        XCTAssertEqual(praxis.gongVolume, 1.0, accuracy: 0.001)
    }

    func testValidation_invalidPreparationTime_snappedToNearest() {
        // 7 is closest to 5 (distance 2) and 10 (distance 3), so snaps to 5
        let praxis = Praxis(name: "Test", preparationTimeSeconds: 7)
        XCTAssertEqual(praxis.preparationTimeSeconds, 5)
    }

    func testValidation_allVolumesClamped() {
        let praxis = Praxis(
            name: "Test",
            gongVolume: 2.0,
            intervalGongVolume: -1.0,
            backgroundSoundVolume: 1.5
        )
        XCTAssertEqual(praxis.gongVolume, 1.0, accuracy: 0.001)
        XCTAssertEqual(praxis.intervalGongVolume, 0.0, accuracy: 0.001)
        XCTAssertEqual(praxis.backgroundSoundVolume, 1.0, accuracy: 0.001)
    }

    // MARK: - Short Description

    func testShortDescription_includesDurationNumber() {
        let praxis = Praxis(name: "Test", durationMinutes: 20)
        XCTAssertTrue(praxis.shortDescription.contains("20"))
    }

    func testShortDescription_silentBackground_includesSilenceLabel() {
        // Given: silent background
        let praxis = Praxis(name: "Test", backgroundSoundId: "silent")

        // Then: shortDescription contains separator between multiple parts
        let desc = praxis.shortDescription
        XCTAssertTrue(desc.contains("·"), "shortDescription should have separator")
        let partsCount = desc.components(separatedBy: " · ").count
        XCTAssertGreaterThan(partsCount, 1)
    }

    func testShortDescription_nonSilentBackground_doesNotIncludeSilenceLabel() {
        let silent = Praxis(name: "Test", backgroundSoundId: "silent")
        let forest = Praxis(name: "Test", backgroundSoundId: "forest")
        // forest has fewer parts (no silence label)
        let silentParts = silent.shortDescription.components(separatedBy: " · ").count
        let forestParts = forest.shortDescription.components(separatedBy: " · ").count
        XCTAssertGreaterThan(silentParts, forestParts)
    }

    func testShortDescription_withPreparationEnabled_includesMoreParts() {
        let withPrep = Praxis(name: "Test", preparationTimeEnabled: true, preparationTimeSeconds: 15)
        let withoutPrep = Praxis(name: "Test", preparationTimeEnabled: false)
        let withParts = withPrep.shortDescription.components(separatedBy: " · ").count
        let withoutParts = withoutPrep.shortDescription.components(separatedBy: " · ").count
        XCTAssertGreaterThan(withParts, withoutParts)
    }

    func testShortDescription_preparationSeconds_includesNumber() {
        let praxis = Praxis(name: "Test", preparationTimeEnabled: true, preparationTimeSeconds: 20)
        XCTAssertTrue(praxis.shortDescription.contains("20"))
    }

    func testShortDescription_validGongId_includesGongName() {
        let praxis = Praxis(name: "Test", startGongSoundId: GongSound.defaultSoundId)
        let gongName = GongSound.find(byId: GongSound.defaultSoundId)?.name ?? ""
        XCTAssertFalse(gongName.isEmpty)
        XCTAssertTrue(praxis.shortDescription.contains(gongName))
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
            introductionId: nil
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
        XCTAssertNil(praxis.introductionId)
    }

    // MARK: - toMeditationSettings

    func testToMeditationSettings_preservesAllFields() {
        // Given
        let praxis = Praxis(
            id: UUID(),
            name: "Test",
            durationMinutes: 25,
            preparationTimeEnabled: false,
            preparationTimeSeconds: 10,
            startGongSoundId: "classic-bowl",
            gongVolume: 0.8,
            introductionId: nil,
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
        XCTAssertNil(settings.introductionId)
        XCTAssertTrue(settings.intervalGongsEnabled)
        XCTAssertEqual(settings.intervalMinutes, 10)
        XCTAssertEqual(settings.intervalMode, .afterStart)
        XCTAssertEqual(settings.intervalSoundId, "temple-bell")
        XCTAssertEqual(settings.intervalGongVolume, 0.6, accuracy: 0.001)
        XCTAssertEqual(settings.backgroundSoundId, "forest")
        XCTAssertEqual(settings.backgroundSoundVolume, 0.3, accuracy: 0.001)
    }
}
