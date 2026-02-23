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
    var onDeletedCalled = false

    // swiftlint:disable:next implicitly_unwrapped_optional
    var testPraxis: Praxis!

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.mockAudioService = MockAudioService()
        self.mockSoundRepository = MockBackgroundSoundRepository()
        self.savedPraxis = nil
        self.onDeletedCalled = false

        self.testPraxis = Praxis(
            name: "Morning Calm",
            durationMinutes: 20,
            preparationTimeEnabled: true,
            preparationTimeSeconds: 10,
            startGongSoundId: "temple-bell",
            gongVolume: 0.8,
            introductionId: nil,
            intervalGongsEnabled: true,
            intervalMinutes: 5,
            intervalMode: .repeating,
            intervalSoundId: "soft-chime",
            intervalGongVolume: 0.6,
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3
        )

        // Ensure the mock repository has this praxis stored
        self.mockRepository.praxes = [self.testPraxis]

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
            soundRepository: self.mockSoundRepository,
            onSaved: { [weak self] praxis in
                self?.savedPraxis = praxis
            },
            onDeleted: { [weak self] in
                self?.onDeletedCalled = true
            }
        )
    }

    // MARK: - Save

    func testSave_persistsUpdatedPraxis() {
        // Given
        self.sut.name = "Evening Calm"
        self.sut.durationMinutes = 30

        // When
        self.sut.save()

        // Then
        let persisted = self.mockRepository.praxes.first { $0.id == self.testPraxis.id }
        XCTAssertEqual(persisted?.name, "Evening Calm")
        XCTAssertEqual(persisted?.durationMinutes, 30)
    }

    func testSave_preservesOriginalId() {
        // Given
        let originalId = self.testPraxis.id
        self.sut.name = "Renamed"

        // When
        self.sut.save()

        // Then
        XCTAssertEqual(self.savedPraxis?.id, originalId)
    }

    func testSave_callsOnSavedWithUpdatedPraxis() {
        // Given
        self.sut.name = "Updated Name"
        self.sut.durationMinutes = 15
        self.sut.backgroundSoundId = "rain"

        // When
        self.sut.save()

        // Then
        XCTAssertNotNil(self.savedPraxis)
        XCTAssertEqual(self.savedPraxis?.name, "Updated Name")
        XCTAssertEqual(self.savedPraxis?.durationMinutes, 15)
        XCTAssertEqual(self.savedPraxis?.backgroundSoundId, "rain")
    }

    // MARK: - canSave

    func testCanSave_falseForEmptyName() {
        // Given
        self.sut.name = ""

        // Then
        XCTAssertFalse(self.sut.canSave)
    }

    func testCanSave_falseForWhitespaceName() {
        // Given
        self.sut.name = "   "

        // Then
        XCTAssertFalse(self.sut.canSave)
    }

    func testCanSave_trueForNonEmptyName() {
        // Given
        self.sut.name = "My Meditation"

        // Then
        XCTAssertTrue(self.sut.canSave)
    }

    // MARK: - Delete

    func testConfirmDelete_callsOnDeletedCallback() {
        // Given: repository has two praxes so deletion is allowed
        let secondPraxis = Praxis(name: "Second")
        self.mockRepository.praxes = [self.testPraxis, secondPraxis]

        // When
        self.sut.confirmDelete()

        // Then
        XCTAssertTrue(self.onDeletedCalled)
    }

    func testConfirmDelete_whenLastPraxis_setsErrorMessage() {
        // Given: only one praxis in repository
        self.mockRepository.praxes = [self.testPraxis]

        // When
        self.sut.confirmDelete()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
    }

    func testConfirmDelete_whenLastPraxis_doesNotCallOnDeleted() {
        // Given: only one praxis in repository
        self.mockRepository.praxes = [self.testPraxis]

        // When
        self.sut.confirmDelete()

        // Then
        XCTAssertFalse(self.onDeletedCalled)
    }

    func testRequestDelete_setsShowDeleteConfirmation() {
        // When
        self.sut.requestDelete()

        // Then
        XCTAssertTrue(self.sut.showDeleteConfirmation)
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
}
