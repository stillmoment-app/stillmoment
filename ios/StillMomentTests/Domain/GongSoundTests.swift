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
            name: GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        )

        XCTAssertEqual(sound.id, "classic-bowl")
        XCTAssertEqual(sound.filename, "singing-bowl-hit-3-33366-10s.mp3")
        XCTAssertEqual(sound.name.en, "Classic Bowl")
        XCTAssertEqual(sound.name.de, "Klassisch")
    }

    // MARK: - Equatable Tests

    func testGongSound_equatable_sameValues_areEqual() {
        let sound1 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        )
        let sound2 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        )

        XCTAssertEqual(sound1, sound2)
    }

    func testGongSound_equatable_differentId_areNotEqual() {
        let sound1 = GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        )
        let sound2 = GongSound(
            id: "temple-bell",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        )

        XCTAssertNotEqual(sound1, sound2)
    }

    // MARK: - Identifiable Tests

    func testGongSound_identifiable_idIsCorrect() {
        let sound = GongSound(
            id: "temple-bell",
            filename: "tibetan-singing-bowl-55786-10s.mp3",
            name: GongSound.LocalizedString(en: "Temple Bell", de: "Tempelglocke")
        )

        XCTAssertEqual(sound.id, "temple-bell")
    }

    // MARK: - LocalizedString Tests

    func testLocalizedString_localized_returnsCorrectLanguage() {
        let localizedString = GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")

        // The actual result depends on the device/simulator locale
        // We just verify it returns one of the valid values
        let result = localizedString.localized
        XCTAssertTrue(result == "Classic Bowl" || result == "Klassisch")
    }

    func testLocalizedString_equatable_sameValues_areEqual() {
        let string1 = GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        let string2 = GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")

        XCTAssertEqual(string1, string2)
    }

    func testLocalizedString_equatable_differentValues_areNotEqual() {
        let string1 = GongSound.LocalizedString(en: "Classic Bowl", de: "Klassisch")
        let string2 = GongSound.LocalizedString(en: "Deep Zen", de: "Tiefer Zen")

        XCTAssertNotEqual(string1, string2)
    }

    // MARK: - Codable Tests

    func testGongSound_codable_encodesAndDecodes() throws {
        let original = GongSound(
            id: "clear-strike",
            filename: "singing-bowl-strike-sound-84682-10s.mp3",
            name: GongSound.LocalizedString(en: "Clear Strike", de: "Klarer Anschlag")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GongSound.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testGongSound_codable_decodesFromJSON() throws {
        let json = """
            {
                "id": "deep-resonance",
                "filename": "singing-bowl-male-frequency-29714-10s.mp3",
                "name": {
                    "en": "Deep Resonance",
                    "de": "Tiefe Resonanz"
                }
            }
            """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let sound = try decoder.decode(GongSound.self, from: data)

        XCTAssertEqual(sound.id, "deep-resonance")
        XCTAssertEqual(sound.filename, "singing-bowl-male-frequency-29714-10s.mp3")
        XCTAssertEqual(sound.name.en, "Deep Resonance")
        XCTAssertEqual(sound.name.de, "Tiefe Resonanz")
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

    func testAllAvailableSounds_hasFourSounds() {
        XCTAssertEqual(GongSound.allSounds.count, 4)
    }

    func testDefaultSound_isTempleBell() {
        XCTAssertEqual(GongSound.defaultSound.id, "temple-bell")
    }

    func testFindById_existingId_returnsSound() {
        let sound = GongSound.find(byId: "clear-strike")

        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, "clear-strike")
        XCTAssertEqual(sound?.name.en, "Clear Strike")
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
}
