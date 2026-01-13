//
//  GuidedMeditationSettingsRepositoryTests.swift
//  Still Moment
//
//  Tests for GuidedMeditationSettingsRepository
//

import XCTest
@testable import StillMoment

final class GuidedMeditationSettingsRepositoryTests: XCTestCase {
    // MARK: - Properties

    private static let suiteName = "GuidedMeditationSettingsRepositoryTests"

    var sut: GuidedMeditationSettingsRepository?
    var testDefaults: UserDefaults?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Use a dedicated suite to isolate test data
        self.testDefaults = UserDefaults(suiteName: Self.suiteName)
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        if let defaults = testDefaults {
            self.sut = GuidedMeditationSettingsRepository(userDefaults: defaults)
        }
    }

    override func tearDown() {
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        self.testDefaults = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Load Tests

    func testLoad_withNoStoredValue_returnsDefault() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // When
        let settings = sut.load()

        // Then
        XCTAssertEqual(settings, .default)
        XCTAssertNil(settings.preparationTimeSeconds)
    }

    func testLoad_withStoredValue_returnsStoredSettings() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        testDefaults.set(15, forKey: "guidedMeditation.preparationTimeSeconds")

        // When
        let settings = sut.load()

        // Then
        XCTAssertEqual(settings.preparationTimeSeconds, 15)
    }

    func testLoad_withStoredZero_returnsDisabled() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given - 0 means disabled (nil)
        testDefaults.set(0, forKey: "guidedMeditation.preparationTimeSeconds")

        // When
        let settings = sut.load()

        // Then
        XCTAssertNil(settings.preparationTimeSeconds)
    }

    // MARK: - Save Tests

    func testSave_withValue_storesInUserDefaults() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        let settings = GuidedMeditationSettings(preparationTimeSeconds: 30)

        // When
        sut.save(settings)

        // Then
        let storedValue = testDefaults.integer(forKey: "guidedMeditation.preparationTimeSeconds")
        XCTAssertEqual(storedValue, 30)
    }

    func testSave_withNil_storesZero() {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        let settings = GuidedMeditationSettings(preparationTimeSeconds: nil)

        // When
        sut.save(settings)

        // Then
        let storedValue = testDefaults.integer(forKey: "guidedMeditation.preparationTimeSeconds")
        XCTAssertEqual(storedValue, 0)
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoad_preservesValue() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: 20)

        // When
        sut.save(original)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded, original)
    }

    func testSaveAndLoad_preservesNil() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let original = GuidedMeditationSettings(preparationTimeSeconds: nil)

        // When
        sut.save(original)
        let loaded = sut.load()

        // Then
        XCTAssertEqual(loaded, original)
        XCTAssertNil(loaded.preparationTimeSeconds)
    }

    func testSaveAndLoad_allValidValues() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Test all valid preparation times
        for value in GuidedMeditationSettings.validPreparationTimeValues {
            // Given
            let settings = GuidedMeditationSettings(preparationTimeSeconds: value)

            // When
            sut.save(settings)
            let loaded = sut.load()

            // Then
            XCTAssertEqual(loaded.preparationTimeSeconds, value, "Failed for value: \(value)")
        }
    }
}
