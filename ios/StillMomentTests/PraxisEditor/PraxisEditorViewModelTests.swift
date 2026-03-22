//
//  PraxisEditorViewModelTests.swift
//  Still Moment
//
//  Tests for PraxisEditorViewModel
//

import XCTest
@testable import StillMoment

@MainActor
final class PraxisEditorViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: PraxisEditorViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockRepository: MockPraxisRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSoundRepository: MockBackgroundSoundRepository!
    var savedPraxis: Praxis?

    // swiftlint:disable:next implicitly_unwrapped_optional
    var testPraxis: Praxis!

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.mockAudioService = MockAudioService()
        self.mockSoundRepository = MockBackgroundSoundRepository()
        self.savedPraxis = nil

        self.testPraxis = Praxis(
            durationMinutes: 20,
            preparationTimeEnabled: true,
            preparationTimeSeconds: 10,
            startGongSoundId: "temple-bell",
            gongVolume: 0.8,
            attunementId: nil,
            intervalGongsEnabled: true,
            intervalMinutes: 5,
            intervalMode: .repeating,
            intervalSoundId: "soft-chime",
            intervalGongVolume: 0.6,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )

        self.mockRepository.currentPraxis = self.testPraxis
        self.sut = self.createSUT(praxis: self.testPraxis)
    }

    override func tearDown() {
        self.sut = nil
        self.mockRepository = nil
        self.mockAudioService = nil
        self.mockSoundRepository = nil
        self.savedPraxis = nil
        self.testPraxis = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createSUT(praxis: Praxis) -> PraxisEditorViewModel {
        PraxisEditorViewModel(
            praxis: praxis,
            repository: self.mockRepository,
            audioService: self.mockAudioService,
            soundRepository: self.mockSoundRepository
        ) { [weak self] praxis in
            self?.savedPraxis = praxis
        }
    }

    // MARK: - Save

    func testSave_persistsUpdatedPraxis() {
        // Given
        self.sut.durationMinutes = 30

        // When
        self.sut.save()

        // Then
        XCTAssertEqual(self.mockRepository.savedPraxis?.durationMinutes, 30)
        XCTAssertEqual(self.mockRepository.savedPraxis?.id, self.testPraxis.id)
    }

    func testSave_preservesOriginalId() {
        // Given
        let originalId = self.testPraxis.id

        // When
        self.sut.save()

        // Then
        XCTAssertEqual(self.savedPraxis?.id, originalId)
    }

    func testSave_callsOnSavedWithUpdatedPraxis() {
        // Given
        self.sut.durationMinutes = 15
        self.sut.backgroundSoundId = "rain"

        // When
        self.sut.save()

        // Then
        XCTAssertNotNil(self.savedPraxis)
        XCTAssertEqual(self.savedPraxis?.durationMinutes, 15)
        XCTAssertEqual(self.savedPraxis?.backgroundSoundId, "rain")
    }

    // MARK: - Audio Preview

    func testPlayGongPreview_callsAudioService() {
        // When
        self.sut.playGongPreview(soundId: "temple-bell", volume: 0.8)

        // Then
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastPreviewSoundId, "temple-bell")
        XCTAssertEqual(self.mockAudioService.lastPreviewVolume, 0.8)
    }

    func testPlayIntervalGongPreview_callsAudioService() {
        // When
        self.sut.playIntervalGongPreview(soundId: "soft-chime", volume: 0.6)

        // Then
        XCTAssertTrue(self.mockAudioService.playGongPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastPreviewSoundId, "soft-chime")
        XCTAssertEqual(self.mockAudioService.lastPreviewVolume, 0.6)
    }

    func testPlayBackgroundPreview_callsAudioService() {
        // When
        self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // Then
        XCTAssertTrue(self.mockAudioService.playBackgroundPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastBackgroundPreviewSoundId, "forest")
        XCTAssertEqual(self.mockAudioService.lastBackgroundPreviewVolume, 0.5)
    }

    func testStopAllPreviews_stopsGongAndBackground() {
        // When
        self.sut.stopAllPreviews()

        // Then
        XCTAssertTrue(self.mockAudioService.stopGongPreviewCalled)
        XCTAssertTrue(self.mockAudioService.stopBackgroundPreviewCalled)
    }

    // MARK: - Attunement Toggle

    func testInit_attunementEnabledFromPraxis() {
        // Given
        let praxis = Praxis(attunementId: "breathing", attunementEnabled: true)

        // When
        let sut = self.createSUT(praxis: praxis)

        // Then
        XCTAssertTrue(sut.attunementEnabled)
        XCTAssertEqual(sut.attunementId, "breathing")
    }

    func testInit_attunementDisabledByDefault() {
        // Then — default testPraxis has no attunement
        XCTAssertFalse(self.sut.attunementEnabled)
    }

    func testSetAttunementEnabled_autoSelectsFirstWhenNilId() {
        // Given — attunementId is nil (default)
        XCTAssertNil(self.sut.attunementId)

        // When
        self.sut.setAttunementEnabled(true)

        // Then
        XCTAssertTrue(self.sut.attunementEnabled)
        let firstAvailable = self.sut.availableAttunements.first?.id
        XCTAssertEqual(self.sut.attunementId, firstAvailable)
    }

    func testSetAttunementEnabled_preservesExistingSelection() {
        // Given — attunementId already set
        self.sut.attunementId = "custom-intro"
        self.sut.attunementEnabled = false

        // When
        self.sut.setAttunementEnabled(true)

        // Then — keeps existing selection
        XCTAssertTrue(self.sut.attunementEnabled)
        XCTAssertEqual(self.sut.attunementId, "custom-intro")
    }

    func testSetAttunementDisabled_preservesAttunementId() {
        // Given
        self.sut.attunementId = "breathing"
        self.sut.attunementEnabled = true

        // When
        self.sut.setAttunementEnabled(false)

        // Then — id preserved for re-enable
        XCTAssertFalse(self.sut.attunementEnabled)
        XCTAssertEqual(self.sut.attunementId, "breathing")
    }

    func testSave_persistsAttunementEnabled() {
        // Given
        self.sut.attunementEnabled = true
        self.sut.attunementId = "breathing"

        // When
        self.sut.save()

        // Then
        XCTAssertEqual(self.savedPraxis?.attunementEnabled, true)
        XCTAssertEqual(self.savedPraxis?.attunementId, "breathing")
    }

    func testSave_persistsAttunementDisabled() {
        // Given
        self.sut.attunementEnabled = false
        self.sut.attunementId = "breathing"

        // When
        self.sut.save()

        // Then
        XCTAssertEqual(self.savedPraxis?.attunementEnabled, false)
        XCTAssertEqual(self.savedPraxis?.attunementId, "breathing")
    }
}
