//
//  PraxisRepositoryTests.swift
//  Still Moment
//
//  Tests for UserDefaultsPraxisRepository (simplified single-config protocol)
//

import XCTest
@testable import StillMoment

final class PraxisRepositoryTests: XCTestCase {
    // MARK: - Properties

    private static let suiteName = "PraxisRepositoryTests"

    var sut: UserDefaultsPraxisRepository?
    var testDefaults: UserDefaults?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        self.testDefaults = UserDefaults(suiteName: Self.suiteName)
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        if let defaults = testDefaults {
            self.sut = UserDefaultsPraxisRepository(userDefaults: defaults)
        }
    }

    override func tearDown() {
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        self.testDefaults = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Fresh Install

    func testLoad_withNoPraxis_returnsDefaultPraxis() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxis = sut.load()
        XCTAssertEqual(praxis.durationMinutes, 10)
    }

    func testLoad_withNoPraxis_defaultPraxisHasDefaultGong() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxis = sut.load()
        XCTAssertEqual(praxis.startGongSoundId, GongSound.defaultSoundId)
    }

    func testLoad_withNoPraxis_defaultHasSilentBackground() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxis = sut.load()
        XCTAssertEqual(praxis.backgroundSoundId, "silent")
    }

    func testLoad_calledTwice_returnsSamePraxis() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let first = sut.load()
        let second = sut.load()
        XCTAssertEqual(first, second)
    }

    // MARK: - Save and Load

    func testSaveAndLoad_roundTrip_preservesAllFields() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let original = Praxis(
            id: UUID(),
            durationMinutes: 30,
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

        sut.save(original)
        let loaded = sut.load()

        XCTAssertEqual(loaded, original)
    }

    func testSave_overwritesPrevious() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        // Initialize with default
        _ = sut.load()
        let updated = Praxis(durationMinutes: 25, backgroundSoundId: "rain")

        sut.save(updated)
        let loaded = sut.load()

        XCTAssertEqual(loaded.durationMinutes, 25)
        XCTAssertEqual(loaded.backgroundSoundId, "rain")
    }

    func testSave_changesArePersistedAcrossInstances() {
        guard let testDefaults else {
            return XCTFail("testDefaults not initialized")
        }
        let repo1 = UserDefaultsPraxisRepository(userDefaults: testDefaults)
        let praxis = Praxis(durationMinutes: 45)
        repo1.save(praxis)

        let repo2 = UserDefaultsPraxisRepository(userDefaults: testDefaults)
        let loaded = repo2.load()

        XCTAssertEqual(loaded.durationMinutes, 45)
    }

    // MARK: - Migration from MeditationSettings

    func testLoad_withExistingMeditationSettings_createsMigratedPraxis() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }
        // Given: existing MeditationSettings in UserDefaults (simulates an app update)
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)
        testDefaults.set(25, forKey: MeditationSettings.Keys.durationMinutes)

        // When
        let praxis = sut.load()

        // Then: migration created a praxis from existing settings
        XCTAssertEqual(praxis.backgroundSoundId, "forest")
        XCTAssertEqual(praxis.durationMinutes, 25)
    }

    func testLoad_withExistingMeditationSettings_migrationRunsOnce() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }
        // Given
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)

        // When: load called twice
        let first = sut.load()
        let second = sut.load()

        // Then: same result on both calls
        XCTAssertEqual(first, second)
    }

    func testLoad_withNoMeditationSettings_createsFreshDefault() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        // No MeditationSettings keys set — fresh install
        let praxis = sut.load()

        XCTAssertEqual(praxis.durationMinutes, 10) // default duration
        XCTAssertEqual(praxis.backgroundSoundId, "silent") // default background
    }
}
