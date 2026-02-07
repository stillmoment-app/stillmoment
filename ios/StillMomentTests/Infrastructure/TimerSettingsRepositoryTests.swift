//
//  TimerSettingsRepositoryTests.swift
//  Still Moment
//
//  Tests for UserDefaultsTimerSettingsRepository
//

import XCTest
@testable import StillMoment

final class TimerSettingsRepositoryTests: XCTestCase {
    // MARK: - Properties

    private static let suiteName = "TimerSettingsRepositoryTests"

    var sut: UserDefaultsTimerSettingsRepository?
    var testDefaults: UserDefaults?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        self.testDefaults = UserDefaults(suiteName: Self.suiteName)
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        if let defaults = testDefaults {
            self.sut = UserDefaultsTimerSettingsRepository(userDefaults: defaults)
        }
    }

    override func tearDown() {
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        self.testDefaults = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Load Default Tests

    func testLoad_withNoStoredValues_returnsDefaults() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // When
        let settings = sut.load()

        // Then
        XCTAssertEqual(settings, .default)
    }

    // MARK: - Save and Load Round-Trip Tests

    func testSaveAndLoad_preservesAllSettings() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let original = MeditationSettings(
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            intervalGongVolume: 0.5,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.8,
            durationMinutes: 25,
            preparationTimeEnabled: false,
            preparationTimeSeconds: 30,
            startGongSoundId: "deep-zen",
            gongVolume: 0.7
        )

        // When
        sut.save(original)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded, original)
    }

    func testSaveAndLoad_preservesIntervalGongsEnabled() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.intervalGongsEnabled = true

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertTrue(loaded.intervalGongsEnabled)
    }

    func testSaveAndLoad_preservesDuration() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.durationMinutes = 45

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.durationMinutes, 45)
    }

    func testSaveAndLoad_preservesBackgroundSoundVolume() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.backgroundSoundVolume = 0.75

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.backgroundSoundVolume, 0.75, accuracy: 0.001)
    }

    func testSaveAndLoad_preservesGongVolume() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.gongVolume = 0.6

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.gongVolume, 0.6, accuracy: 0.001)
    }

    func testSaveAndLoad_preservesPreparationSettings() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.preparationTimeEnabled = false
        settings.preparationTimeSeconds = 30

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertFalse(loaded.preparationTimeEnabled)
        XCTAssertEqual(loaded.preparationTimeSeconds, 30)
    }

    func testSaveAndLoad_preservesStartGongSoundId() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        var settings = MeditationSettings.default
        settings.startGongSoundId = "warm-zen"

        // When
        sut.save(settings)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.startGongSoundId, "warm-zen")
    }

    // MARK: - Volume Default Handling

    func testLoad_withNoStoredVolume_returnsDefaultBackgroundVolume() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Store only some keys, not volume
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)

        // When
        let settings = sut.load()

        // Then
        XCTAssertEqual(
            settings.backgroundSoundVolume,
            MeditationSettings.defaultBackgroundSoundVolume,
            accuracy: 0.001
        )
    }

    func testLoad_withNoStoredGongVolume_returnsDefaultGongVolume() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Store only some keys, not gong volume
        testDefaults.set(true, forKey: MeditationSettings.Keys.intervalGongsEnabled)

        // When
        let settings = sut.load()

        // Then
        XCTAssertEqual(
            settings.gongVolume,
            MeditationSettings.defaultGongVolume,
            accuracy: 0.001
        )
    }

    // MARK: - Legacy Migration

    func testLoad_withLegacySilentMode_migratesCorrectly() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Legacy setting exists, new key does not
        testDefaults.set("Silent", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When
        let settings = sut.load()

        // Then - Should migrate to "silent"
        XCTAssertEqual(settings.backgroundSoundId, "silent")

        // And - Migration should write the new key
        let storedId = testDefaults.string(forKey: MeditationSettings.Keys.backgroundSoundId)
        XCTAssertEqual(storedId, "silent")
    }

    func testLoad_withLegacyWhiteNoiseMode_migratesCorrectly() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Legacy "White Noise" setting
        testDefaults.set("White Noise", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When
        let settings = sut.load()

        // Then - Should migrate to "silent" (White Noise was removed)
        XCTAssertEqual(settings.backgroundSoundId, "silent")
    }

    func testLoad_withNewSoundId_ignoresLegacyMode() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Both legacy and new keys exist
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)
        testDefaults.set("Silent", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When
        let settings = sut.load()

        // Then - Should use new key, not legacy
        XCTAssertEqual(settings.backgroundSoundId, "forest")
    }

    // MARK: - Interval Minutes Default

    func testLoad_withZeroIntervalMinutes_returnsDefault() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Zero stored (UserDefaults returns 0 for missing integers)
        testDefaults.set(0, forKey: MeditationSettings.Keys.intervalMinutes)

        // When
        let settings = sut.load()

        // Then - Should use default (5)
        XCTAssertEqual(settings.intervalMinutes, 5)
    }

    // MARK: - Overwrite Tests

    func testSave_overwritesPreviousSettings() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given - Save initial settings
        var first = MeditationSettings.default
        first.durationMinutes = 10
        sut.save(first)

        // When - Save different settings
        var second = MeditationSettings.default
        second.durationMinutes = 30
        sut.save(second)

        // Then - Should have latest settings
        let loaded = sut.load()
        XCTAssertEqual(loaded.durationMinutes, 30)
    }
}
