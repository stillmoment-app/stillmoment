//
//  GuidedMeditationsListViewModelTests.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

// MARK: - Mock Metadata Service

final class MockAudioMetadataService: AudioMetadataServiceProtocol {
    var extractedMetadata: AudioMetadata?
    var extractShouldThrow = false

    func extractMetadata(from url: URL) async throws -> AudioMetadata {
        if self.extractShouldThrow {
            throw AudioMetadataError.invalidAudioFile
        }
        let metadata = AudioMetadata(
            artist: "Test Artist",
            title: "Test Title",
            duration: 600
        )
        self.extractedMetadata = metadata
        return metadata
    }
}

// MARK: - Mock Meditation Service (Extended)

final class MockGuidedMeditationServiceExtended: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation] = []
    var loadShouldThrow = false
    var addShouldThrow = false
    var updateShouldThrow = false
    var deleteShouldThrow = false

    func loadMeditations() throws -> [GuidedMeditation] {
        if self.loadShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        return self.meditations
    }

    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        if self.addShouldThrow {
            throw GuidedMeditationError.bookmarkCreationFailed
        }

        let meditation = GuidedMeditation(
            fileBookmark: Data(),
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown",
            name: metadata.title ?? "Untitled"
        )
        self.meditations.append(meditation)
        return meditation
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {
        if self.updateShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        if let index = self.meditations.firstIndex(where: { $0.id == meditation.id }) {
            self.meditations[index] = meditation
        }
    }

    func deleteMeditation(id: UUID) throws {
        if self.deleteShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        self.meditations.removeAll { $0.id == id }
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        if self.loadShouldThrow {
            throw GuidedMeditationError.persistenceFailed(reason: "Mock error")
        }
        self.meditations = meditations
    }

    func resolveBookmark(_ bookmark: Data) throws -> URL {
        URL(fileURLWithPath: "/tmp/test.mp3")
    }

    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        true
    }

    func stopAccessingSecurityScopedResource(_ url: URL) {
        // Mock implementation
    }
}

// MARK: - GuidedMeditationsListViewModelTests

@MainActor
final class GuidedMeditationsListViewModelTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationsListViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationServiceExtended!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMetadataService: MockAudioMetadataService!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationServiceExtended()
        self.mockMetadataService = MockAudioMetadataService()
        self.sut = GuidedMeditationsListViewModel(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertFalse(self.sut.isLoading)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.showingDocumentPicker)
        XCTAssertFalse(self.sut.showingEditSheet)
        XCTAssertNil(self.sut.meditationToEdit)
    }

    // MARK: - Load Meditations Tests

    func testLoadMeditationsSuccess() {
        // Given
        let meditation1 = self.createTestMeditation(teacher: "A", name: "Med1")
        let meditation2 = self.createTestMeditation(teacher: "B", name: "Med2")
        self.mockMeditationService.meditations = [meditation1, meditation2]

        // When
        self.sut.loadMeditations()

        // Then
        XCTAssertEqual(self.sut.meditations.count, 2)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)
    }

    func testLoadMeditationsEmpty() {
        // Given - No meditations
        self.mockMeditationService.meditations = []

        // When
        self.sut.loadMeditations()

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)
    }

    func testLoadMeditationsFailure() {
        // Given
        self.mockMeditationService.loadShouldThrow = true

        // When
        self.sut.loadMeditations()

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)
    }

    // MARK: - Import Meditation Tests

    func testImportMeditationSuccess() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")

        // When
        await self.sut.importMeditation(from: url)

        // Then
        XCTAssertEqual(self.sut.meditations.count, 1)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)

        // Verify metadata was extracted
        XCTAssertNotNil(self.mockMetadataService.extractedMetadata)
    }

    func testImportMeditationMetadataExtractionFails() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        self.mockMetadataService.extractShouldThrow = true

        // When
        await self.sut.importMeditation(from: url)

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)
    }

    func testImportMeditationServiceFails() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        self.mockMeditationService.addShouldThrow = true

        // When
        await self.sut.importMeditation(from: url)

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertFalse(self.sut.isLoading)
    }

    // MARK: - Delete Meditation Tests

    func testDeleteMeditationSuccess() {
        // Given
        let meditation = self.createTestMeditation()
        self.mockMeditationService.meditations = [meditation]
        self.sut.loadMeditations()
        XCTAssertEqual(self.sut.meditations.count, 1)

        // When
        self.sut.deleteMeditation(meditation)

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertTrue(self.mockMeditationService.meditations.isEmpty)
        XCTAssertNil(self.sut.errorMessage)
    }

    func testDeleteMeditationFailure() {
        // Given
        let meditation = self.createTestMeditation()
        self.mockMeditationService.meditations = [meditation]
        self.sut.loadMeditations()
        self.mockMeditationService.deleteShouldThrow = true

        // When
        self.sut.deleteMeditation(meditation)

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
        // UI array should still have it since service failed
        XCTAssertEqual(self.sut.meditations.count, 1)
    }

    func testDeleteNonExistentMeditation() {
        // Given
        let existingMeditation = self.createTestMeditation(name: "Existing")
        let nonExistentMeditation = self.createTestMeditation(name: "NonExistent")
        self.mockMeditationService.meditations = [existingMeditation]
        self.sut.loadMeditations()

        // When
        self.sut.deleteMeditation(nonExistentMeditation)

        // Then
        // Should not fail, just remove from UI array
        XCTAssertEqual(self.sut.meditations.count, 1)
        XCTAssertNil(self.sut.errorMessage)
    }

    // MARK: - Update Meditation Tests

    func testUpdateMeditationSuccess() {
        // Given
        let meditation = self.createTestMeditation()
        self.mockMeditationService.meditations = [meditation]
        self.sut.loadMeditations()

        var updatedMeditation = meditation
        updatedMeditation.customName = "Updated Name"

        // When
        self.sut.updateMeditation(updatedMeditation)

        // Then
        XCTAssertNil(self.sut.errorMessage)
        // Should reload from service
        XCTAssertEqual(self.sut.meditations.count, 1)
    }

    func testUpdateMeditationFailure() {
        // Given
        let meditation = self.createTestMeditation()
        self.mockMeditationService.meditations = [meditation]
        self.sut.loadMeditations()
        self.mockMeditationService.updateShouldThrow = true

        // When
        self.sut.updateMeditation(meditation)

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
    }

    // MARK: - Show/Hide UI Tests

    func testShowDocumentPicker() {
        // When
        self.sut.showDocumentPicker()

        // Then
        XCTAssertTrue(self.sut.showingDocumentPicker)
    }

    func testShowEditSheet() {
        // Given
        let meditation = self.createTestMeditation()

        // When
        self.sut.showEditSheet(for: meditation)

        // Then
        XCTAssertTrue(self.sut.showingEditSheet)
        XCTAssertNotNil(self.sut.meditationToEdit)
        XCTAssertEqual(self.sut.meditationToEdit?.id, meditation.id)
    }

    // MARK: - Grouping Tests

    func testMeditationsByTeacherEmpty() {
        // Given - No meditations
        self.sut.meditations = []

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then
        XCTAssertTrue(grouped.isEmpty)
    }

    func testMeditationsByTeacherSingleTeacher() {
        // Given
        let med1 = self.createTestMeditation(teacher: "Alice", name: "Med1")
        let med2 = self.createTestMeditation(teacher: "Alice", name: "Med2")
        self.sut.meditations = [med1, med2]

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].teacher, "Alice")
        XCTAssertEqual(grouped[0].meditations.count, 2)
    }

    func testMeditationsByTeacherMultipleTeachers() {
        // Given
        let med1 = self.createTestMeditation(teacher: "Bob", name: "Med1")
        let med2 = self.createTestMeditation(teacher: "Alice", name: "Med2")
        let med3 = self.createTestMeditation(teacher: "Charlie", name: "Med3")
        self.sut.meditations = [med1, med2, med3]

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then
        XCTAssertEqual(grouped.count, 3)

        // Should be sorted alphabetically
        XCTAssertEqual(grouped[0].teacher, "Alice")
        XCTAssertEqual(grouped[1].teacher, "Bob")
        XCTAssertEqual(grouped[2].teacher, "Charlie")

        // Each should have one meditation
        XCTAssertEqual(grouped[0].meditations.count, 1)
        XCTAssertEqual(grouped[1].meditations.count, 1)
        XCTAssertEqual(grouped[2].meditations.count, 1)
    }

    func testMeditationsByTeacherWithCustomNames() {
        // Given
        var meditation = self.createTestMeditation(teacher: "Original", name: "Original")
        meditation.customTeacher = "Custom Teacher"
        self.sut.meditations = [meditation]

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then
        XCTAssertEqual(grouped.count, 1)
        // Should use effectiveTeacher (custom if available)
        XCTAssertEqual(grouped[0].teacher, "Custom Teacher")
    }

    func testMeditationsByTeacherSorting() {
        // Given - Teachers in non-alphabetical order
        let med1 = self.createTestMeditation(teacher: "Zara", name: "Med1")
        let med2 = self.createTestMeditation(teacher: "Alice", name: "Med2")
        let med3 = self.createTestMeditation(teacher: "Bob", name: "Med3")
        self.sut.meditations = [med1, med2, med3]

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then - Should be sorted alphabetically
        XCTAssertEqual(grouped[0].teacher, "Alice")
        XCTAssertEqual(grouped[1].teacher, "Bob")
        XCTAssertEqual(grouped[2].teacher, "Zara")
    }

    func testMeditationsByTeacherCaseInsensitiveSorting() {
        // Given
        let med1 = self.createTestMeditation(teacher: "zara", name: "Med1")
        let med2 = self.createTestMeditation(teacher: "Alice", name: "Med2")
        let med3 = self.createTestMeditation(teacher: "BOB", name: "Med3")
        self.sut.meditations = [med1, med2, med3]

        // When
        let grouped = self.sut.meditationsByTeacher()

        // Then - Should be case-insensitive sorted
        XCTAssertEqual(grouped[0].teacher, "Alice")
        XCTAssertEqual(grouped[1].teacher, "BOB")
        XCTAssertEqual(grouped[2].teacher, "zara")
    }

    // MARK: - Loading State Tests

    func testLoadingStateDuringLoad() {
        // Given
        self.mockMeditationService.meditations = []

        // When - Call loadMeditations
        // Note: This is synchronous in the current implementation
        self.sut.isLoading = true // Simulate loading start
        self.sut.loadMeditations()

        // Then
        XCTAssertFalse(self.sut.isLoading) // Should be false after completion
    }

    // MARK: - Error Clearing Tests

    func testErrorMessageClearedOnNextOperation() {
        // Given - Error from previous operation
        self.mockMeditationService.loadShouldThrow = true
        self.sut.loadMeditations()
        XCTAssertNotNil(self.sut.errorMessage)

        // When - Perform successful operation
        self.mockMeditationService.loadShouldThrow = false
        self.sut.loadMeditations()

        // Then - Error should be cleared
        XCTAssertNil(self.sut.errorMessage)
    }

    func testErrorMessageClearedOnImport() async {
        // Given - Error from previous operation
        self.mockMeditationService.loadShouldThrow = true
        self.sut.loadMeditations()
        XCTAssertNotNil(self.sut.errorMessage)

        // When - Start import
        self.mockMeditationService.loadShouldThrow = false
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        await self.sut.importMeditation(from: url)

        // Then - Error should have been cleared at start
        XCTAssertNil(self.sut.errorMessage)
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createTestMeditation(teacher: String = "Teacher", name: String = "Meditation") -> GuidedMeditation {
        GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name
        )
    }
}
