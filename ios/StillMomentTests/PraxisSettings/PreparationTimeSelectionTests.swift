//
//  PreparationTimeSelectionTests.swift
//  Still Moment
//
//  Tests for the preparation-time editing behavior used by
//  PreparationTimeSelectionView (shared-083, redesigned shared-119).
//
//  The redesigned screen binds the master switch directly to
//  `preparationTimeEnabled` and the slider to `preparationTimeSeconds`.
//  Turning the switch off only flips `enabled`; the chosen duration is
//  retained so re-enabling restores it (no reset to default).
//

import XCTest
@testable import StillMoment

@MainActor
final class PreparationTimeSelectionTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: PraxisSettingsViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.sut = PraxisSettingsViewModel(
            praxis: .default,
            repository: self.mockRepository,
            audioService: MockAudioService(),
            soundRepository: MockBackgroundSoundRepository()
        ) { _ in }
    }

    override func tearDown() {
        self.sut = nil
        self.mockRepository = nil
        super.tearDown()
    }

    // MARK: - Default

    func testDefault_isEnabledWithTenSeconds() {
        // Given: a fresh view model from Praxis.default
        // Then: preparation is on with the new default of 10 seconds
        XCTAssertTrue(self.sut.preparationTimeEnabled)
        XCTAssertEqual(self.sut.preparationTimeSeconds, 10)
    }

    // MARK: - Remembered duration (shared-119)

    func testTurningOff_keepsChosenSeconds() {
        // Given: a chosen duration of 30 with the switch on
        self.sut.preparationTimeSeconds = 30
        self.sut.preparationTimeEnabled = true

        // When: the user turns the switch off
        self.sut.preparationTimeEnabled = false

        // Then: the chosen duration is retained (no reset)
        XCTAssertEqual(self.sut.preparationTimeSeconds, 30)
    }

    func testTurningOffAndOnAgain_restoresChosenSeconds() {
        // Given: a chosen duration of 35 with the switch on
        self.sut.preparationTimeSeconds = 35
        self.sut.preparationTimeEnabled = true

        // When: the user turns the switch off and on again
        self.sut.preparationTimeEnabled = false
        self.sut.preparationTimeEnabled = true

        // Then: the previously chosen duration is restored, not reset to default
        XCTAssertTrue(self.sut.preparationTimeEnabled)
        XCTAssertEqual(self.sut.preparationTimeSeconds, 35)
    }
}
