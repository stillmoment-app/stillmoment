//
//  FileOpenHandlerImportFlowTests.swift
//  Still Moment
//
//  Tests for the share/open-with import flow (ios-042: always meditation).
//

import XCTest
@testable import StillMoment

@MainActor
final class FileOpenHandlerImportFlowTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: FileOpenHandler!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMetadataService: MockAudioMetadataService!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockMetadataService = MockAudioMetadataService()
        self.sut = FileOpenHandler(
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

    // MARK: - Direct Import on Share (Pending-Flow)

    func testImportFile_validMP3_doesNotAddToLibraryYet() async {
        // Given — Persistenz erfolgt erst nach Save im Edit-Sheet (ios-043).
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = await self.sut.importFile(from: url)

        // Then
        guard case .success = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertTrue(self.mockMeditationService.meditations.isEmpty)
    }

    func testImportFile_validMP3_publishesPendingImportSignal() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        _ = await self.sut.importFile(from: url)

        // Then — Library beobachtet pendingImport und oeffnet das Edit-Sheet
        XCTAssertNotNil(self.sut.pendingImportSignal)
        XCTAssertEqual(self.sut.pendingImportSignal?.url.lastPathComponent, "meditation.mp3")
    }

    func testImportFile_unsupportedFormat_returnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        let result = await self.sut.importFile(from: url)

        // Then
        guard case let .failure(error) = result else {
            XCTFail("Expected failure, got \(result)")
            return
        }
        XCTAssertEqual(error, .unsupportedFormat)
        XCTAssertNil(self.sut.pendingImportSignal)
    }

    func testImportFile_duplicate_returnsAlreadyImported() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let existing = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existing]

        // When
        let result = await self.sut.importFile(from: url)

        // Then
        guard case let .failure(error) = result else {
            XCTFail("Expected failure, got \(result)")
            return
        }
        guard case .alreadyImported = error else {
            XCTFail("Expected alreadyImported, got \(error)")
            return
        }
    }

    func testImportFile_metadataFailure_returnsImportFailed() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        self.mockMetadataService.extractShouldThrow = true

        // When
        let result = await self.sut.importFile(from: url)

        // Then
        guard case let .failure(error) = result else {
            XCTFail("Expected failure, got \(result)")
            return
        }
        XCTAssertEqual(error, .importFailed)
    }

    // MARK: - shouldStopMeditation Signal

    func testImportFile_validFile_signalsRunningMeditationToStop() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        XCTAssertFalse(self.sut.shouldStopMeditation)

        // When
        _ = await self.sut.importFile(from: url)

        // Then — eine laufende Meditation (Timer/Player) muss beim Import beendet werden
        XCTAssertTrue(self.sut.shouldStopMeditation)
    }

    func testImportFile_unsupportedFormat_doesNotSignalStop() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        _ = await self.sut.importFile(from: url)

        // Then — abgelehnte Datei darf keine laufende Meditation stoppen
        XCTAssertFalse(self.sut.shouldStopMeditation)
    }
}
