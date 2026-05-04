//
//  PraxisEditorViewModelCustomAudioTests.swift
//  Still Moment
//
//  Tests for PraxisEditorViewModel custom audio management
//

import XCTest
@testable import StillMoment

@MainActor
final class PraxisEditorViewModelCustomAudioTests: XCTestCase {
    // MARK: - Properties

    private var mockCustomAudioRepo: MockCustomAudioRepository?
    private var mockPraxisRepo: MockPraxisRepository?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        self.mockCustomAudioRepo = MockCustomAudioRepository()
        self.mockPraxisRepo = MockPraxisRepository()
    }

    override func tearDown() {
        self.mockCustomAudioRepo = nil
        self.mockPraxisRepo = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createSUT(
        praxis: Praxis = .default,
        customAudioRepo: MockCustomAudioRepository? = nil,
        praxisRepo: MockPraxisRepository? = nil
    ) -> PraxisEditorViewModel {
        let audioRepo = customAudioRepo ?? self.mockCustomAudioRepo ?? MockCustomAudioRepository()
        let repo = praxisRepo ?? self.mockPraxisRepo ?? MockPraxisRepository()
        return PraxisEditorViewModel(
            praxis: praxis,
            repository: repo,
            audioService: MockAudioService(),
            soundRepository: MockBackgroundSoundRepository(),
            customAudioRepository: audioRepo
        ) { _ in }
    }

    // MARK: - importCustomAudio

    func testImportCustomAudio_soundscape_setsBackgroundSoundId() {
        // Given
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        let sut = self.createSUT()
        let url = URL(fileURLWithPath: "/tmp/sound.mp3")

        // When
        sut.importCustomAudio(from: url)

        // Then
        let imported = mockRepo.stubbedSoundscapes.first
        XCTAssertNotNil(imported)
        XCTAssertEqual(sut.backgroundSoundId, imported?.id.uuidString)
    }

    func testImportCustomAudio_error_setsCustomAudioError() {
        // Given
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.shouldThrowOnImport = CustomAudioError.unsupportedFormat("ogg")
        let sut = self.createSUT()
        let url = URL(fileURLWithPath: "/tmp/sound.ogg")

        // When
        sut.importCustomAudio(from: url)

        // Then
        XCTAssertNotNil(sut.customAudioError)
    }

    // MARK: - deleteCustomAudio

    func testDeleteCustomAudio_soundscape_resetsToSilent() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let praxis = Praxis(backgroundSoundId: file.id.uuidString)
        let sut = self.createSUT(praxis: praxis)
        sut.backgroundSoundId = file.id.uuidString

        // When
        sut.deleteCustomAudio(file)

        // Then
        XCTAssertEqual(sut.backgroundSoundId, "silent")
        XCTAssertTrue(mockRepo.deletedIds.contains(file.id))
    }

    func testDeleteCustomAudio_doesNotResetUnrelatedSelection() {
        // Given - background sound is a different ID than the deleted file
        let file = CustomAudioFile(
            id: UUID(),
            name: "ToDelete",
            filename: "delete.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()
        sut.backgroundSoundId = "forest"

        // When
        sut.deleteCustomAudio(file)

        // Then - forest remains selected because it was not the deleted file
        XCTAssertEqual(sut.backgroundSoundId, "forest")
    }

    // MARK: - usageCount

    func testUsageCount_soundscape_countsCurrentPraxisUsingIt() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            dateAdded: Date()
        )
        let praxis = Praxis(backgroundSoundId: file.id.uuidString)
        guard let mockPraxisRepo = self.mockPraxisRepo else {
            return XCTFail("mockPraxisRepo not initialized")
        }
        mockPraxisRepo.currentPraxis = praxis
        let sut = self.createSUT(praxis: praxis)

        // When
        let count = sut.usageCount(for: file)

        // Then
        XCTAssertEqual(count, 1)
    }

    func testUsageCount_noUsage_returnsZero() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Unused",
            filename: "unused.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockPraxisRepo = self.mockPraxisRepo else {
            return XCTFail("mockPraxisRepo not initialized")
        }
        mockPraxisRepo.currentPraxis = .default
        let sut = self.createSUT()

        // When
        let count = sut.usageCount(for: file)

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - renameCustomAudio

    func testRenameCustomAudio_updatesList() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Old Name",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()

        // When
        sut.renameCustomAudio(file, newName: "New Name")

        // Then — mock was called with updated file
        XCTAssertEqual(mockRepo.updatedFiles.first?.name, "New Name")
        XCTAssertEqual(mockRepo.updatedFiles.first?.id, file.id)
    }

    func testRenameCustomAudio_refreshesPublishedList() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Before",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()

        // When — mock updates the stub in-place (MockCustomAudioRepository.update does this)
        sut.renameCustomAudio(file, newName: "After")

        // Then — customSoundscapes reflects the rename
        XCTAssertEqual(sut.customSoundscapes.first?.name, "After")
    }

    func testRenameCustomAudio_ignoresEmptyName() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Original",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()

        // When — empty string
        sut.renameCustomAudio(file, newName: "")

        // Then — update was never called
        XCTAssertTrue(mockRepo.updatedFiles.isEmpty)
    }

    func testRenameCustomAudio_ignoresWhitespaceOnlyName() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Original",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()

        // When — whitespace only
        sut.renameCustomAudio(file, newName: "   ")

        // Then — update was never called
        XCTAssertTrue(mockRepo.updatedFiles.isEmpty)
    }

    func testRenameCustomAudio_trimsWhitespace() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Name",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let sut = self.createSUT()

        // When — name with surrounding whitespace
        sut.renameCustomAudio(file, newName: "  Trimmed  ")

        // Then — stored name is trimmed
        XCTAssertEqual(mockRepo.updatedFiles.first?.name, "Trimmed")
    }

    func testRenameCustomAudio_error_setsCustomAudioError() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Name",
            filename: "sound.mp3",
            duration: 60,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        mockRepo.shouldThrowOnUpdate = CustomAudioError.fileNotFound(file.id)
        let sut = self.createSUT()

        // When
        sut.renameCustomAudio(file, newName: "New")

        // Then
        XCTAssertNotNil(sut.customAudioError)
    }

    // MARK: - loadCustomAudio

    func testLoadCustomAudio_populatesPublishedLists() {
        // Given
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        let soundscape = CustomAudioFile(
            id: UUID(),
            name: "Rain",
            filename: "rain.mp3",
            duration: 120,
            dateAdded: Date()
        )
        mockRepo.stubbedSoundscapes = [soundscape]

        // When - init calls loadCustomAudio()
        let sut = self.createSUT()

        // Then
        XCTAssertEqual(sut.customSoundscapes.count, 1)
        XCTAssertEqual(sut.customSoundscapes.first?.name, "Rain")
    }
}
