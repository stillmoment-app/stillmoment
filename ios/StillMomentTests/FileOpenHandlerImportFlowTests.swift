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

    // MARK: - Vorschlaege aus dem Podcast-Verzeichnis (shared-128)

    func testImportFile_preferredValuesWinOverFileTags() async {
        // Given — Datei hat nichtssagende ID3-Tags, das Podcast-Verzeichnis kennt Titel und Autor
        self.mockMetadataService.fixedMetadata = AudioMetadata(artist: "DLF", title: "ep_123", duration: 1234)
        let url = URL(fileURLWithPath: "/tmp/folge.mp3")

        // When
        _ = await self.sut.importFile(
            from: url,
            preferredTitle: "Body Scan (20:34 Min.)",
            preferredArtist: "Deutschlandfunk Nova"
        )

        // Then
        XCTAssertEqual(self.sut.pendingImportSignal?.metadata.title, "Body Scan (20:34 Min.)")
        XCTAssertEqual(self.sut.pendingImportSignal?.metadata.artist, "Deutschlandfunk Nova")
        XCTAssertEqual(self.sut.pendingImportSignal?.metadata.duration, 1234)
    }

    func testImportFile_withoutPreferredValuesUsesFileTags() async {
        // Given — normaler Link-Import ohne Vorschlaege
        self.mockMetadataService.fixedMetadata = AudioMetadata(artist: "Tara Brach", title: "RAIN", duration: 600)
        let url = URL(fileURLWithPath: "/tmp/rain.mp3")

        // When
        _ = await self.sut.importFile(from: url, preferredTitle: nil, preferredArtist: nil)

        // Then
        XCTAssertEqual(self.sut.pendingImportSignal?.metadata.title, "RAIN")
        XCTAssertEqual(self.sut.pendingImportSignal?.metadata.artist, "Tara Brach")
    }

    // MARK: - Uebernahme des ausstehenden Imports (ios-060)

    func testPendingImportCanBeTakenOverAfterImport() async {
        // Given — Import kommt an, waehrend die Bibliothek noch nicht aufgebaut ist
        self.mockMetadataService.fixedMetadata = AudioMetadata(artist: "Tara Brach", title: "RAIN", duration: 600)
        _ = await self.sut.importFile(from: URL(fileURLWithPath: "/tmp/rain.mp3"))

        // When — die Bibliothek erscheint und uebernimmt den Import
        let taken = self.sut.takePendingImport()

        // Then — sie bekommt die Datei mit den Vorschlaegen
        XCTAssertEqual(taken?.url.lastPathComponent, "rain.mp3")
        XCTAssertEqual(taken?.metadata.title, "RAIN")
        XCTAssertEqual(taken?.metadata.artist, "Tara Brach")
    }

    func testPendingImportIsTakenOverOnlyOnce() async {
        // Given
        _ = await self.sut.importFile(from: URL(fileURLWithPath: "/tmp/meditation.mp3"))
        let first = self.sut.takePendingImport()

        // When — die Bibliothek erscheint erneut
        let second = self.sut.takePendingImport()

        // Then — das Bearbeiten-Blatt oeffnet sich nicht ein zweites Mal
        XCTAssertNotNil(first)
        XCTAssertNil(second)
        XCTAssertNil(self.sut.pendingImportSignal)
    }

    func testNoPendingImportWithoutImport() {
        XCTAssertNil(self.sut.takePendingImport())
    }

    func testNoPendingImportAfterDuplicate() async {
        // Given — die Datei liegt schon in der Bibliothek
        self.mockMeditationService.meditations = [
            GuidedMeditation(
                localFilePath: "existing.mp3",
                fileName: "meditation.mp3",
                duration: 600,
                teacher: "Teacher",
                name: "Existing"
            )
        ]

        // When
        _ = await self.sut.importFile(from: URL(fileURLWithPath: "/tmp/meditation.mp3"))

        // Then
        XCTAssertNil(self.sut.takePendingImport())
    }
}
