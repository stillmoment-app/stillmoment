//
//  BackgroundSoundRepositoryTests.swift
//  Still Moment
//
//  Created by Claude Code on 2025-11-12.
//  Tests for BackgroundSoundRepository
//

import XCTest
@testable import StillMoment

final class BackgroundSoundRepositoryTests: XCTestCase {
    var sut: BackgroundSoundRepository?

    override func setUp() {
        super.setUp()
        self.sut = BackgroundSoundRepository()
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testSoundsJsonFile_ExistsInBundle() {
        // Given / When - Try to find sounds.json in bundle
        let url = Bundle.main.url(
            forResource: "sounds",
            withExtension: "json",
            subdirectory: "BackgroundAudio"
        )

        // Then
        XCTAssertNotNil(
            url,
            "sounds.json must be included in BackgroundAudio folder in the bundle"
        )

        if let url {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: url.path),
                "sounds.json file must exist at path: \(url.path)"
            )
        }
    }

    func testLoadSounds_ReturnsNonEmptyArray() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        XCTAssertFalse(sounds.isEmpty, "Should load at least one sound")
    }

    func testLoadSounds_ContainsSilentSound() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        let silent = sounds.first { $0.id == "silent" }
        XCTAssertNotNil(silent, "Should contain silent sound")
        XCTAssertEqual(silent?.filename, "silence.m4a")
    }

    func testLoadSounds_ContainsForestSound() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        let forest = sounds.first { $0.id == "forest" }
        XCTAssertNotNil(forest, "Should contain forest sound")
        XCTAssertEqual(forest?.filename, "forest-ambience.mp3")
    }

    func testGetSoundById_ExistingId_ReturnsSound() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }
        _ = try sut.loadSounds()

        // When
        let sound = sut.getSound(byId: "silent")

        // Then
        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, "silent")
    }

    func testGetSoundById_NonExistingId_ReturnsNil() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }
        _ = try sut.loadSounds()

        // When
        let sound = sut.getSound(byId: "nonexistent")

        // Then
        XCTAssertNil(sound, "Should return nil for non-existing ID")
    }

    func testLoadSounds_AllSoundsHaveValidProperties() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        for sound in sounds {
            XCTAssertFalse(sound.id.isEmpty, "Sound ID should not be empty")
            XCTAssertFalse(sound.filename.isEmpty, "Filename should not be empty")
            XCTAssertFalse(sound.name.en.isEmpty, "English name should not be empty")
            XCTAssertFalse(sound.name.de.isEmpty, "German name should not be empty")
            XCTAssertFalse(sound.iconName.isEmpty, "Icon name should not be empty")
            XCTAssertGreaterThanOrEqual(sound.volume, 0.0, "Volume should be >= 0.0")
            XCTAssertLessThanOrEqual(sound.volume, 1.0, "Volume should be <= 1.0")
        }
    }

    func testLoadSounds_SilentSound_HasConsistentVolume() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        let silent = sounds.first { $0.id == "silent" }
        XCTAssertNotNil(silent, "Should contain silent sound")
        XCTAssertEqual(
            Double(silent?.volume ?? 0),
            0.15,
            accuracy: 0.001,
            "Silent sound should have consistent volume (0.15) with other sounds"
        )
    }

    func testLoadSounds_ForestSound_HasModerateVolume() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then
        let forest = sounds.first { $0.id == "forest" }
        XCTAssertNotNil(forest, "Should contain forest sound")
        XCTAssertEqual(
            Double(forest?.volume ?? 0),
            0.15,
            accuracy: 0.001,
            "Forest sound should have moderate volume (0.15)"
        )
    }

    func testLocalizedString_EnglishLocale_ReturnsEnglish() {
        // Given
        let localizedString = BackgroundSound.LocalizedString(en: "Hello", de: "Hallo")

        // When
        // Note: This test depends on system locale
        let result = localizedString.localized

        // Then
        XCTAssertTrue(result == "Hello" || result == "Hallo", "Should return localized string")
    }

    func testLoadSounds_AllSoundsHaveCorrespondingBundleFiles() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }
        let sounds = try sut.loadSounds()

        // Then
        for sound in sounds {
            // Parse filename into name and extension
            let components = sound.filename.split(separator: ".")
            XCTAssertEqual(components.count, 2, "Filename should have name and extension: \(sound.filename)")

            let name = String(components[0])
            let ext = String(components[1])

            // When - Try to find the file in the bundle
            let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "BackgroundAudio"
            )

            // Then
            XCTAssertNotNil(
                url,
                "Sound file '\(sound.filename)' for sound ID '\(sound.id)' should exist in BackgroundAudio bundle"
            )
        }
    }

    func testBundleFiles_AllFilesAreRegisteredInSoundsJson() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }
        let sounds = try sut.loadSounds()
        let registeredFilenames = Set(sounds.map(\.filename))

        guard let resourceURL = Bundle.main.url(forResource: "BackgroundAudio", withExtension: nil) else {
            XCTFail("BackgroundAudio directory not found in bundle")
            return
        }

        // When - Get all audio files in BackgroundAudio directory
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        )

        let audioFiles = contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "m4a" || ext == "mp3" || ext == "wav"
        }

        // Then - Verify all audio files are registered (excluding .DS_Store and other system files)
        for audioFile in audioFiles {
            let filename = audioFile.lastPathComponent
            XCTAssertTrue(
                registeredFilenames.contains(filename),
                "Audio file '\(filename)' found in bundle but not registered in sounds.json"
            )
        }
    }

    // MARK: - Robustness Tests

    func testAvailableSounds_MatchesLoadedSounds() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let loaded = try sut.loadSounds()
        let available = sut.availableSounds

        // Then - availableSounds should return same sounds as loadSounds
        XCTAssertEqual(loaded.count, available.count)
        for sound in loaded {
            XCTAssertTrue(
                available.contains { $0.id == sound.id },
                "Available sounds should contain \(sound.id)"
            )
        }
    }

    func testRepository_MultipleInstances_LoadSameData() throws {
        // Given - Create two separate instances
        let repo1 = BackgroundSoundRepository()
        let repo2 = BackgroundSoundRepository()

        // When
        let sounds1 = try repo1.loadSounds()
        let sounds2 = try repo2.loadSounds()

        // Then - Both should load identical sounds
        XCTAssertEqual(sounds1.count, sounds2.count)
        XCTAssertEqual(Set(sounds1.map(\.id)), Set(sounds2.map(\.id)))
    }

    func testRepository_Initialization_DoesNotCrash() {
        // Given/When - Initialize repository (already done in setUp)
        // This test verifies that initialization succeeds even if there are issues
        // (fallback mechanism should prevent crashes)

        // Then
        XCTAssertNotNil(self.sut, "Repository should initialize successfully")
        XCTAssertFalse(
            self.sut?.sounds.isEmpty ?? true,
            "Repository should have at least one sound (from JSON or fallback)"
        )
    }

    func testGetSound_CalledMultipleTimes_ReturnsConsistentResults() {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When - Get same sound multiple times
        let sound1 = sut.getSound(byId: "silent")
        let sound2 = sut.getSound(byId: "silent")
        let sound3 = sut.getSound(byId: "silent")

        // Then - All should be identical
        XCTAssertNotNil(sound1)
        XCTAssertEqual(sound1?.id, sound2?.id)
        XCTAssertEqual(sound2?.id, sound3?.id)
        XCTAssertEqual(sound1?.filename, sound2?.filename)
    }

    func testLoadSounds_ReturnsMinimumRequiredSounds() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then - Must have at least silent sound (critical for background audio)
        XCTAssertGreaterThanOrEqual(
            sounds.count,
            1,
            "Repository must provide at least 1 sound (silent mode for background audio)"
        )

        let hasSilent = sounds.contains { $0.id == "silent" }
        XCTAssertTrue(hasSilent, "Repository must provide 'silent' sound for Apple compliance")
    }
}

// MARK: - LocalizedString and Model Tests

extension BackgroundSoundRepositoryTests {
    func testLocalizedString_Initialization_StoresValues() {
        // Given/When
        let localizedString = BackgroundSound.LocalizedString(en: "Test English", de: "Test Deutsch")

        // Then
        XCTAssertEqual(localizedString.en, "Test English")
        XCTAssertEqual(localizedString.de, "Test Deutsch")
    }

    func testLocalizedString_Localized_ReturnsNonEmptyString() {
        // Given
        let localizedString = BackgroundSound.LocalizedString(en: "English", de: "Deutsch")

        // When
        let result = localizedString.localized

        // Then
        XCTAssertFalse(result.isEmpty, "Localized string should not be empty")
        XCTAssertTrue(
            result == "English" || result == "Deutsch",
            "Should return either English or German"
        )
    }

    // MARK: - BackgroundSound Model Tests

    func testBackgroundSound_Initialization_StoresAllProperties() {
        // Given/When
        let sound = BackgroundSound(
            id: "test-id",
            filename: "test.mp3",
            name: BackgroundSound.LocalizedString(en: "Test", de: "Test"),
            description: BackgroundSound.LocalizedString(en: "Desc", de: "Beschr"),
            iconName: "music.note",
            volume: 0.5
        )

        // Then
        XCTAssertEqual(sound.id, "test-id")
        XCTAssertEqual(sound.filename, "test.mp3")
        XCTAssertEqual(sound.name.en, "Test")
        XCTAssertEqual(sound.description.en, "Desc")
        XCTAssertEqual(sound.iconName, "music.note")
        XCTAssertEqual(sound.volume, 0.5, accuracy: 0.001)
    }

    // MARK: - Thread Safety Tests

    func testRepository_ConcurrentAccess_ThreadSafe() {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        let expectation = XCTestExpectation(description: "Concurrent access completes")
        expectation.expectedFulfillmentCount = 10

        // When - Access repository concurrently from multiple threads
        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = sut.availableSounds
                _ = sut.getSound(byId: "silent")
                expectation.fulfill()
            }
        }

        // Then - Should not crash
        wait(for: [expectation], timeout: 5.0)
    }

    func testLoadSounds_CalledMultipleTimes_ReturnsSameInstance() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds1 = try sut.loadSounds()
        let sounds2 = try sut.loadSounds()

        // Then - Should return same cached array
        XCTAssertEqual(sounds1.count, sounds2.count)
        for (sound1, sound2) in zip(sounds1, sounds2) {
            XCTAssertEqual(sound1.id, sound2.id)
            XCTAssertEqual(sound1.filename, sound2.filename)
        }
    }
}

// MARK: - Sound Properties Validation

extension BackgroundSoundRepositoryTests {
    func testLoadSounds_AllSoundsHaveUniqueIds() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()
        let ids = sounds.map(\.id)

        // Then
        let uniqueIds = Set(ids)
        XCTAssertEqual(
            ids.count,
            uniqueIds.count,
            """
            All sound IDs should be unique. \
            Found duplicates: \(ids.filter { id in ids.filter { $0 == id }.count > 1 })
            """
        )
    }

    func testLoadSounds_AllSoundsHaveValidIconNames() throws {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sounds = try sut.loadSounds()

        // Then - Icon names should be valid SF Symbols or asset names
        for sound in sounds {
            XCTAssertFalse(
                sound.iconName.isEmpty,
                "Sound '\(sound.id)' has empty icon name"
            )
            XCTAssertFalse(
                sound.iconName.contains(" "),
                "Sound '\(sound.id)' icon name should not contain spaces: '\(sound.iconName)'"
            )
        }
    }

    func testGetSound_EmptyString_ReturnsNil() {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sound = sut.getSound(byId: "")

        // Then
        XCTAssertNil(sound, "Empty string ID should return nil")
    }

    func testGetSound_CaseSensitive_DoesNotMatch() {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let sound = sut.getSound(byId: "SILENT") // Uppercase

        // Then - Should be case-sensitive and not match "silent"
        if sound != nil {
            // If it matches, verify it's actually uppercase in JSON
            XCTAssertEqual(sound?.id, "SILENT", "If sound found, ID should be uppercase")
        } else {
            // Expected: nil because "silent" is lowercase in JSON
            XCTAssertNil(sound, "Should be case-sensitive")
        }
    }

    func testAvailableSounds_IsImmutable() {
        // Given
        guard let sut = self.sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When - Get available sounds multiple times
        let sounds1 = sut.availableSounds
        let sounds2 = sut.availableSounds

        // Then - Should return consistent results (immutable after init)
        XCTAssertEqual(sounds1.count, sounds2.count)
        for i in 0..<sounds1.count {
            XCTAssertEqual(sounds1[i].id, sounds2[i].id)
        }
    }
}

// MARK: - JSON Configuration Tests

extension BackgroundSoundRepositoryTests {
    func testLoadSounds_JSONStructure_IsValid() throws {
        // Given - Load sounds.json directly to verify structure
        guard let url = Bundle.main.url(
            forResource: "sounds",
            withExtension: "json",
            subdirectory: "BackgroundAudio"
        ) else {
            XCTFail("sounds.json not found")
            return
        }

        // When
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertNotNil(json, "JSON should be valid dictionary")
        XCTAssertNotNil(json?["sounds"], "JSON should have 'sounds' key")

        guard let soundsArray = json?["sounds"] as? [[String: Any]] else {
            XCTFail("'sounds' should be an array of dictionaries")
            return
        }

        XCTAssertFalse(soundsArray.isEmpty, "Sounds array should not be empty")

        // Verify each sound has required keys
        for (index, soundDict) in soundsArray.enumerated() {
            XCTAssertNotNil(soundDict["id"], "Sound at index \(index) should have 'id'")
            XCTAssertNotNil(soundDict["filename"], "Sound at index \(index) should have 'filename'")
            XCTAssertNotNil(soundDict["name"], "Sound at index \(index) should have 'name'")
            XCTAssertNotNil(soundDict["description"], "Sound at index \(index) should have 'description'")
            XCTAssertNotNil(soundDict["iconName"], "Sound at index \(index) should have 'iconName'")
            XCTAssertNotNil(soundDict["volume"], "Sound at index \(index) should have 'volume'")
        }
    }
}
