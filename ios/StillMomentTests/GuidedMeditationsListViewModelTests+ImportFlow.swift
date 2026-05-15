//
//  GuidedMeditationsListViewModelTests+ImportFlow.swift
//  Still Moment
//
//  Tests fuer den Pending-Import-Flow (ios-043): Prefill, Cancel, Save.
//

import XCTest
@testable import StillMoment

@MainActor
extension GuidedMeditationsListViewModelTests {
    // MARK: - Import-Eintritt

    func testImportMeditationOpensSheetButLeavesLibraryEmpty() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")

        // When
        await self.sut.importMeditation(from: url)

        // Then — Persistenz erst nach Save; Library bleibt leer.
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNotNil(self.sut.pendingImport)
        XCTAssertTrue(self.sut.showingEditSheet)
        XCTAssertNotNil(self.sut.meditationToEdit)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertNotNil(self.mockMetadataService.extractedMetadata)
    }

    func testImportMeditationDraftPrefilledFromID3() async {
        // Given — Mock liefert artist="Test Artist", title="Test Title"
        let url = URL(fileURLWithPath: "/tmp/test.mp3")

        // When
        await self.sut.importMeditation(from: url)

        // Then
        XCTAssertEqual(self.sut.meditationToEdit?.teacher, "Test Artist")
        XCTAssertEqual(self.sut.meditationToEdit?.name, "Test Title")
    }

    func testImportMeditationDraftIsEmptyForUUIDFileWithoutUsefulMetadata() async {
        // Given
        self.mockMetadataService.fixedMetadata = AudioMetadata(
            artist: "Unknown Artist",
            title: nil,
            duration: 600
        )
        let url = URL(fileURLWithPath: "/tmp/d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3")

        // When
        await self.sut.importMeditation(from: url)

        // Then — UUID-Filename + Unknown-Artist → keine Vorschlaege, Felder leer.
        XCTAssertEqual(self.sut.meditationToEdit?.teacher, "")
        XCTAssertEqual(self.sut.meditationToEdit?.name, "")
    }

    func testImportMeditationUsesKnownTeachersFromLibrary() async {
        // Given — Library kennt "Tara Brach" bereits.
        let existing = self.makeTestMeditation(teacher: "Tara Brach", name: "Bestehende Meditation")
        self.mockMeditationService.meditations = [existing]
        self.sut.loadMeditations()
        await self.waitForImportFlow()

        self.mockMetadataService.fixedMetadata = AudioMetadata(artist: nil, title: nil, duration: 600)
        let url = URL(fileURLWithPath: "/tmp/bodyscan-tara_brach.mp3")

        // When
        await self.sut.importMeditation(from: url)

        // Then — Teacher aus knownTeachers gematched, Filename-Rest als Title.
        XCTAssertEqual(self.sut.meditationToEdit?.teacher, "Tara Brach")
        XCTAssertEqual(self.sut.meditationToEdit?.name, "bodyscan")
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
        XCTAssertNil(self.sut.pendingImport)
        XCTAssertFalse(self.sut.showingEditSheet)
    }

    // MARK: - Cancel + Save

    func testCancelImportLeavesLibraryEmptyAndClearsPending() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        await self.sut.importMeditation(from: url)
        XCTAssertNotNil(self.sut.pendingImport)

        // When
        self.sut.cancelImport()

        // Then
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNil(self.sut.pendingImport)
        XCTAssertFalse(self.sut.showingEditSheet)
        XCTAssertNil(self.sut.meditationToEdit)
    }

    func testSaveImportedMeditationPersistsWithEditedValues() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        await self.sut.importMeditation(from: url)
        guard let draft = sut.meditationToEdit else {
            XCTFail("Edit-Sheet sollte mit Draft geoeffnet sein")
            return
        }
        var edited = draft
        edited.teacher = "Edited Teacher"
        edited.name = "Edited Name"

        // When
        self.sut.handleEditSheetSave(edited)

        // Then
        XCTAssertEqual(self.sut.meditations.count, 1)
        XCTAssertEqual(self.sut.meditations.first?.teacher, "Edited Teacher")
        XCTAssertEqual(self.sut.meditations.first?.name, "Edited Name")
        XCTAssertNil(self.sut.pendingImport)
        XCTAssertFalse(self.sut.showingEditSheet)
        XCTAssertNil(self.sut.errorMessage)
    }

    func testSaveImportedMeditationFailureSetsErrorAndKeepsLibraryEmpty() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        await self.sut.importMeditation(from: url)
        guard let draft = sut.meditationToEdit else {
            XCTFail("Edit-Sheet sollte mit Draft geoeffnet sein")
            return
        }
        self.mockMeditationService.addShouldThrow = true

        // When
        self.sut.handleEditSheetSave(draft)

        // Then — Persistenz schlaegt fehl, Library bleibt leer, Error gesetzt.
        XCTAssertTrue(self.sut.meditations.isEmpty)
        XCTAssertNotNil(self.sut.errorMessage)
    }

    // MARK: - Helpers (file-local)

    private func makeTestMeditation(teacher: String, name: String) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name
        )
    }

    private func waitForImportFlow() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
}
