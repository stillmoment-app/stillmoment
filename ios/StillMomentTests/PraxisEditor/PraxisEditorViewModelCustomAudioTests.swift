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
            customAudioRepository: audioRepo,
            onSaved: { _ in },
            onDeleted: {}
        )
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
        sut.importCustomAudio(from: url, type: .soundscape)

        // Then
        let imported = mockRepo.stubbedSoundscapes.first
        XCTAssertNotNil(imported)
        XCTAssertEqual(sut.backgroundSoundId, imported?.id.uuidString)
    }

    func testImportCustomAudio_attunement_setsIntroductionId() {
        // Given
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        let sut = self.createSUT()
        let url = URL(fileURLWithPath: "/tmp/intro.mp3")

        // When
        sut.importCustomAudio(from: url, type: .attunement)

        // Then
        let imported = mockRepo.stubbedAttunements.first
        XCTAssertNotNil(imported)
        XCTAssertEqual(sut.introductionId, imported?.id.uuidString)
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
        sut.importCustomAudio(from: url, type: .soundscape)

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
            type: .soundscape,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedSoundscapes = [file]
        let praxis = Praxis(
            name: "Test",
            backgroundSoundId: file.id.uuidString
        )
        let sut = self.createSUT(praxis: praxis)
        sut.backgroundSoundId = file.id.uuidString

        // When
        sut.deleteCustomAudio(file)

        // Then
        XCTAssertEqual(sut.backgroundSoundId, "silent")
        XCTAssertTrue(mockRepo.deletedIds.contains(file.id))
    }

    func testDeleteCustomAudio_attunement_resetsIntroductionToNil() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            type: .attunement,
            dateAdded: Date()
        )
        guard let mockRepo = self.mockCustomAudioRepo else {
            return XCTFail("mockCustomAudioRepo not initialized")
        }
        mockRepo.stubbedAttunements = [file]
        let praxis = Praxis(name: "Test")
        let sut = self.createSUT(praxis: praxis)
        sut.introductionId = file.id.uuidString

        // When
        sut.deleteCustomAudio(file)

        // Then
        XCTAssertNil(sut.introductionId)
        XCTAssertTrue(mockRepo.deletedIds.contains(file.id))
    }

    func testDeleteCustomAudio_doesNotResetUnrelatedSelection() {
        // Given - background sound is a different ID than the deleted file
        let file = CustomAudioFile(
            id: UUID(),
            name: "ToDelete",
            filename: "delete.mp3",
            duration: 60,
            type: .soundscape,
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

    func testUsageCount_soundscape_countsPraxesUsingIt() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Test",
            filename: "test.mp3",
            duration: 60,
            type: .soundscape,
            dateAdded: Date()
        )
        let praxis = Praxis(name: "Test", backgroundSoundId: file.id.uuidString)
        guard let mockPraxisRepo = self.mockPraxisRepo else {
            return XCTFail("mockPraxisRepo not initialized")
        }
        mockPraxisRepo.praxes = [praxis]
        let sut = self.createSUT(praxis: praxis)

        // When
        let count = sut.usageCount(for: file)

        // Then
        XCTAssertEqual(count, 1)
    }

    func testUsageCount_attunement_countsPraxesUsingIt() {
        // Given
        let file = CustomAudioFile(
            id: UUID(),
            name: "Intro",
            filename: "intro.mp3",
            duration: 30,
            type: .attunement,
            dateAdded: Date()
        )
        let praxis = Praxis(name: "Test", introductionId: file.id.uuidString)
        guard let mockPraxisRepo = self.mockPraxisRepo else {
            return XCTFail("mockPraxisRepo not initialized")
        }
        mockPraxisRepo.praxes = [praxis]
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
            type: .soundscape,
            dateAdded: Date()
        )
        guard let mockPraxisRepo = self.mockPraxisRepo else {
            return XCTFail("mockPraxisRepo not initialized")
        }
        mockPraxisRepo.praxes = [Praxis(name: "Default")]
        let sut = self.createSUT()

        // When
        let count = sut.usageCount(for: file)

        // Then
        XCTAssertEqual(count, 0)
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
            type: .soundscape,
            dateAdded: Date()
        )
        let attunement = CustomAudioFile(
            id: UUID(),
            name: "Welcome",
            filename: "welcome.mp3",
            duration: 30,
            type: .attunement,
            dateAdded: Date()
        )
        mockRepo.stubbedSoundscapes = [soundscape]
        mockRepo.stubbedAttunements = [attunement]

        // When - init calls loadCustomAudio()
        let sut = self.createSUT()

        // Then
        XCTAssertEqual(sut.customSoundscapes.count, 1)
        XCTAssertEqual(sut.customSoundscapes.first?.name, "Rain")
        XCTAssertEqual(sut.customAttunements.count, 1)
        XCTAssertEqual(sut.customAttunements.first?.name, "Welcome")
    }
}
