//
//  PreparationTimeSelectionTests.swift
//  Still Moment
//
//  Tests for the preparation-time selection helpers used by
//  PreparationTimeSelectionView (shared-083).
//

import XCTest
@testable import StillMoment

@MainActor
final class PreparationTimeSelectionTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: PraxisEditorViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.sut = PraxisEditorViewModel(
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

    // MARK: - selectPreparationTime

    func testSelectOff_disablesPreparation() {
        // Given
        self.sut.preparationTimeEnabled = true
        self.sut.preparationTimeSeconds = 15

        // When
        self.sut.selectPreparationTime(seconds: nil)

        // Then
        XCTAssertFalse(self.sut.preparationTimeEnabled)
    }

    func testSelectSeconds_enablesAndPersistsValue() {
        // Given: starts at default (enabled=true, seconds=10)
        // When
        self.sut.selectPreparationTime(seconds: 30)

        // Then
        XCTAssertTrue(self.sut.preparationTimeEnabled)
        XCTAssertEqual(self.sut.preparationTimeSeconds, 30)
    }

    func testSelectSeconds_whenPreviouslyOff_re_enables() {
        // Given
        self.sut.preparationTimeEnabled = false

        // When
        self.sut.selectPreparationTime(seconds: 5)

        // Then
        XCTAssertTrue(self.sut.preparationTimeEnabled)
        XCTAssertEqual(self.sut.preparationTimeSeconds, 5)
    }

    func testAllSupportedSecondsAreAccepted() {
        // Each of the six supported values should round-trip correctly.
        for seconds in [5, 10, 15, 20, 30, 45] {
            self.sut.selectPreparationTime(seconds: seconds)
            XCTAssertTrue(self.sut.preparationTimeEnabled)
            XCTAssertEqual(self.sut.preparationTimeSeconds, seconds)
        }
    }

    // MARK: - isPreparationTimeSelected

    func testIsSelected_offOption_whenDisabled() {
        self.sut.preparationTimeEnabled = false

        XCTAssertTrue(self.sut.isPreparationTimeSelected(seconds: nil))
        XCTAssertFalse(self.sut.isPreparationTimeSelected(seconds: 10))
    }

    func testIsSelected_secondsOption_matchesEnabledAndValue() {
        self.sut.preparationTimeEnabled = true
        self.sut.preparationTimeSeconds = 15

        XCTAssertFalse(self.sut.isPreparationTimeSelected(seconds: nil))
        XCTAssertTrue(self.sut.isPreparationTimeSelected(seconds: 15))
        XCTAssertFalse(self.sut.isPreparationTimeSelected(seconds: 10))
    }

    func testIsSelected_secondsOption_returnsFalseWhenDisabled() {
        // Even if seconds matches, a disabled toggle means "Off" is selected.
        self.sut.preparationTimeEnabled = false
        self.sut.preparationTimeSeconds = 15

        XCTAssertFalse(self.sut.isPreparationTimeSelected(seconds: 15))
    }
}
