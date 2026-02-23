//
//  PraxisRepositoryTests.swift
//  Still Moment
//
//  Tests for UserDefaultsPraxisRepository
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

    // MARK: - Fresh Install (Erstinstallation)

    func testLoadAll_withNoPraxes_returnsOnePraxis() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxes = sut.loadAll()
        XCTAssertEqual(praxes.count, 1)
    }

    func testLoadAll_withNoPraxes_defaultPraxisHasDefaultDuration() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxis = sut.loadAll().first
        XCTAssertEqual(praxis?.durationMinutes, 10)
    }

    func testLoadAll_withNoPraxes_defaultPraxisHasDefaultGong() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let praxis = sut.loadAll().first
        XCTAssertEqual(praxis?.startGongSoundId, GongSound.defaultSoundId)
    }

    func testLoadAll_calledTwice_returnsSamePraxis() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let first = sut.loadAll()
        let second = sut.loadAll()
        XCTAssertEqual(first, second)
    }

    // MARK: - CRUD

    func testSave_newPraxis_canBeLoadedById() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let id = UUID()
        let praxis = Praxis(id: id, name: "Morning", durationMinutes: 20)

        sut.save(praxis)
        let loaded = sut.load(byId: id)

        XCTAssertEqual(loaded, praxis)
    }

    func testSave_existingPraxis_updatesIt() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let id = try XCTUnwrap(sut.loadAll().first?.id)
        let updated = Praxis(id: id, name: "Updated Name", durationMinutes: 30)

        sut.save(updated)
        let loaded = sut.load(byId: id)

        XCTAssertEqual(loaded?.name, "Updated Name")
        XCTAssertEqual(loaded?.durationMinutes, 30)
    }

    func testLoadAll_afterSavingNewPraxis_includesNewPraxis() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        // Initialize with default
        _ = sut.loadAll()
        let newPraxis = Praxis(id: UUID(), name: "Evening", durationMinutes: 15)

        sut.save(newPraxis)
        let all = sut.loadAll()

        XCTAssertTrue(all.contains(newPraxis))
        XCTAssertEqual(all.count, 2)
    }

    func testLoad_byId_notFound_returnsNil() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let result = sut.load(byId: UUID())
        XCTAssertNil(result)
    }

    // MARK: - Delete

    func testDelete_withMultiplePraxes_removesCorrectOne() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let idToDelete = UUID()
        let keepPraxis = Praxis(id: UUID(), name: "Keep", durationMinutes: 10)
        let deletePraxis = Praxis(id: idToDelete, name: "Delete", durationMinutes: 20)
        sut.save(keepPraxis)
        sut.save(deletePraxis)

        try sut.delete(id: idToDelete)
        let all = sut.loadAll()

        XCTAssertFalse(all.contains { $0.id == idToDelete })
    }

    func testDelete_lastPraxis_throwsCannotDeleteLastPraxis() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let lastId = try XCTUnwrap(sut.loadAll().first?.id)

        XCTAssertThrowsError(try sut.delete(id: lastId)) { error in
            XCTAssertEqual(error as? PraxisRepositoryError, .cannotDeleteLastPraxis)
        }
    }

    func testDelete_nonExistentId_throwsPraxisNotFound() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let fakeId = UUID()

        XCTAssertThrowsError(try sut.delete(id: fakeId)) { error in
            guard case let PraxisRepositoryError.praxisNotFound(id) = error else {
                return XCTFail("Expected praxisNotFound error")
            }
            XCTAssertEqual(id, fakeId)
        }
    }

    // MARK: - Active Praxis ID

    func testActivePraxisId_initiallyNil() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        XCTAssertNil(sut.activePraxisId)
    }

    func testSetActivePraxisId_canBeRetrieved() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let id = UUID()

        sut.setActivePraxisId(id)

        XCTAssertEqual(sut.activePraxisId, id)
    }

    func testSetActivePraxisId_overwritesPrevious() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let first = UUID()
        let second = UUID()

        sut.setActivePraxisId(first)
        sut.setActivePraxisId(second)

        XCTAssertEqual(sut.activePraxisId, second)
    }

    // MARK: - Migration

    func testLoadAll_withExistingMeditationSettings_createsMigratedPraxis() throws {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }
        // Given: existing MeditationSettings in UserDefaults (simulates an app update)
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)
        testDefaults.set(25, forKey: MeditationSettings.Keys.durationMinutes)

        // When
        let praxes = sut.loadAll()

        // Then: migration created one praxis from existing settings
        XCTAssertEqual(praxes.count, 1)
        let praxis = try XCTUnwrap(praxes.first)
        XCTAssertEqual(praxis.backgroundSoundId, "forest")
        XCTAssertEqual(praxis.durationMinutes, 25)
    }

    func testLoadAll_withExistingMeditationSettings_migrationRunsOnce() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }
        // Given
        testDefaults.set("forest", forKey: MeditationSettings.Keys.backgroundSoundId)

        // When: loadAll called twice
        let first = sut.loadAll()
        let second = sut.loadAll()

        // Then: same result, only one praxis
        XCTAssertEqual(first, second)
        XCTAssertEqual(second.count, 1)
    }

    func testLoadAll_withNoMeditationSettings_createsFreshDefault() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        // No MeditationSettings keys set — fresh install
        let praxes = sut.loadAll()

        XCTAssertEqual(praxes.count, 1)
        XCTAssertEqual(praxes.first?.durationMinutes, 10) // default duration
        XCTAssertEqual(praxes.first?.backgroundSoundId, "silent") // default background
    }

    // MARK: - Persistence Round-Trip

    func testSaveAndLoad_roundTrip_preservesAllFields() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }
        let id = UUID()
        let original = Praxis(
            id: id,
            name: "Test Praxis",
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
        let loaded = sut.load(byId: id)

        XCTAssertEqual(loaded, original)
    }
}
