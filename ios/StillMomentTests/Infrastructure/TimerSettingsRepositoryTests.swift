//
//  TimerSettingsRepositoryTests.swift
//  Still Moment
//
//  Tests for UserDefaultsTimerSettingsRepository (legacy, read-only migration)
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

    // MARK: - Load From UserDefaults Tests

    func testLoad_readsAllSettingsFromUserDefaults() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - Populate UserDefaults directly (simulating legacy data)
        testDefaults.set(true, forKey: MeditationSettings.Keys.intervalGongsEnabled)
        testDefaults.set(10, forKey: MeditationSettings.Keys.intervalMinutes)
        testDefaults.set(0.5, forKey: MeditationSettings.Keys.intervalGongVolume)
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)
        testDefaults.set(0.8, forKey: MeditationSettings.Keys.backgroundSoundVolume)
        testDefaults.set(25, forKey: MeditationSettings.Keys.durationMinutes)
        testDefaults.set(false, forKey: MeditationSettings.Keys.preparationTimeEnabled)
        testDefaults.set(30, forKey: MeditationSettings.Keys.preparationTimeSeconds)
        testDefaults.set("deep-zen", forKey: MeditationSettings.Keys.startGongSoundId)
        testDefaults.set(0.7, forKey: MeditationSettings.Keys.gongVolume)

        // When
        let loaded = sut.load()

        // Then
        let expected = MeditationSettings(
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
        XCTAssertEqual(loaded, expected)
    }

    func testLoad_readsIntervalGongsEnabled() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        testDefaults.set(true, forKey: MeditationSettings.Keys.intervalGongsEnabled)

        // When
        let loaded = sut.load()

        // Then
        XCTAssertTrue(loaded.intervalGongsEnabled)
    }

    func testLoad_readsDuration() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        testDefaults.set(45, forKey: MeditationSettings.Keys.durationMinutes)

        // When
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded.durationMinutes, 45)
    }

    func testLoad_readsPreparationSettings() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        testDefaults.set(false, forKey: MeditationSettings.Keys.preparationTimeEnabled)
        testDefaults.set(30, forKey: MeditationSettings.Keys.preparationTimeSeconds)

        // When
        let loaded = sut.load()

        // Then
        XCTAssertFalse(loaded.preparationTimeEnabled)
        XCTAssertEqual(loaded.preparationTimeSeconds, 30)
    }

    func testLoad_readsStartGongSoundId() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        testDefaults.set("warm-zen", forKey: MeditationSettings.Keys.startGongSoundId)

        // When
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
}
