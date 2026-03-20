//
//  GongSoundTests.swift
//  Still Moment
//
//  Domain Tests - GongSound Model
//

import XCTest
@testable import StillMoment

final class GongSoundTests: XCTestCase {
    // MARK: - Creation Tests

    func testGongSound_creation_setsAllProperties() {
        let sound = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: "Classic Bowl"
        )

        XCTAssertEqual(sound.id, "classic-bowl")
        XCTAssertEqual(sound.filename, "singing-bowl-hit-3-33366-10s.mp3")
        XCTAssertEqual(sound.name, "Classic Bowl")
    }

    // MARK: - Equatable Tests

    func testGongSound_equatable_sameValues_areEqual() {
        let sound1 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: "Classic Bowl"
        )
        let sound2 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: "Classic Bowl"
        )

        XCTAssertEqual(sound1, sound2)
    }

    func testGongSound_equatable_differentId_areNotEqual() {
        let sound1 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: "Classic Bowl"
        )
        let sound2 = GongSound(
            id: "temple-bell",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: "Classic Bowl"
        )

        XCTAssertNotEqual(sound1, sound2)
    }

    // MARK: - Identifiable Tests

    func testGongSound_identifiable_idIsCorrect() {
        let sound = GongSound(
            id: "temple-bell",
            filename: "tibetan-singing-bowl-55786-10s.mp3",
            name: "Temple Bell"
        )

        XCTAssertEqual(sound.id, "temple-bell")
    }

    // MARK: - Localized Name Tests

    func testGongSound_name_isNonEmpty() {
        for sound in GongSound.allSounds {
            XCTAssertFalse(sound.name.isEmpty, "Gong sound '\(sound.id)' should have a non-empty name")
        }
    }

    // MARK: - All Available Sounds Tests

    func testAllAvailableSounds_containsExpectedIds() {
        let expectedIds = ["classic-bowl", "deep-resonance", "clear-strike", "temple-bell"]

        for id in expectedIds {
            XCTAssertNotNil(
                GongSound.allSounds.first { $0.id == id },
                "Expected sound with id '\(id)' to exist"
            )
        }
    }

    func testAllAvailableSounds_hasFiveSounds() {
        XCTAssertEqual(GongSound.allSounds.count, 5)
    }

    func testDefaultSound_isTempleBell() {
        XCTAssertEqual(GongSound.defaultSound.id, "temple-bell")
    }

    func testFindById_existingId_returnsSound() {
        let sound = GongSound.find(byId: "clear-strike")

        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, "clear-strike")
        XCTAssertFalse(sound?.name.isEmpty ?? true, "Found sound should have a name")
    }

    func testFindById_nonExistingId_returnsNil() {
        let sound = GongSound.find(byId: "non-existing-sound")

        XCTAssertNil(sound)
    }

    func testFindByIdOrDefault_existingId_returnsSound() {
        let sound = GongSound.findOrDefault(byId: "deep-resonance")

        XCTAssertEqual(sound.id, "deep-resonance")
    }

    func testFindByIdOrDefault_nonExistingId_returnsDefault() {
        let sound = GongSound.findOrDefault(byId: "non-existing-sound")

        XCTAssertEqual(sound.id, "temple-bell")
    }

    // MARK: - Interval Sounds

    func testAllIntervalSounds_containsSoftIntervalTone() {
        XCTAssertNotNil(
            GongSound.allIntervalSounds.first { $0.id == "soft-interval" },
            "Interval sounds should contain soft interval tone"
        )
    }

    func testAllIntervalSounds_hasSixSounds() {
        XCTAssertEqual(GongSound.allIntervalSounds.count, 6)
    }

    func testAllSounds_vibrationIsLast() {
        XCTAssertEqual(GongSound.allSounds.last?.id, GongSound.vibrationId)
    }

    func testAllIntervalSounds_vibrationIsLast() {
        XCTAssertEqual(GongSound.allIntervalSounds.last?.id, GongSound.vibrationId)
    }

    func testFindById_vibration_returnsVibrationSound() {
        let sound = GongSound.find(byId: GongSound.vibrationId)

        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, GongSound.vibrationId)
    }

    func testFindByIdOrDefault_vibration_returnsVibrationSound() {
        let sound = GongSound.findOrDefault(byId: GongSound.vibrationId)

        XCTAssertEqual(sound.id, GongSound.vibrationId)
    }
}
