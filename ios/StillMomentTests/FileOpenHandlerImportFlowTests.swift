//
//  FileOpenHandlerImportFlowTests.swift
//  Still Moment
//
//  Tests for FileOpenHandler import flow state management (shared-073)
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
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCustomAudioRepo: MockCustomAudioRepository!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockMetadataService = MockAudioMetadataService()
        self.mockCustomAudioRepo = MockCustomAudioRepository()
        self.sut = FileOpenHandler(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService,
            customAudioRepository: self.mockCustomAudioRepo
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockCustomAudioRepo = nil
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        super.tearDown()
    }

    // MARK: - Prepare Import

    func testPrepareImport_validFile_setsShowImportTypeSelection() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        self.sut.prepareImport(url: url)

        // Then
        XCTAssertTrue(self.sut.showImportTypeSelection)
        XCTAssertEqual(self.sut.pendingImportURL, url)
    }

    func testPrepareImport_validFile_setsShouldStopMeditation() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        self.sut.prepareImport(url: url)

        // Then
        XCTAssertTrue(self.sut.shouldStopMeditation)
    }

    func testPrepareImport_unsupportedFormat_doesNotShowSheet() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        self.sut.prepareImport(url: url)

        // Then
        XCTAssertFalse(self.sut.showImportTypeSelection)
        XCTAssertNil(self.sut.pendingImportURL)
    }

    // MARK: - Cancel Import

    func testCancelPendingImport_clearsAllState() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        self.sut.prepareImport(url: url)
        XCTAssertTrue(self.sut.showImportTypeSelection)
        XCTAssertTrue(self.sut.shouldStopMeditation)

        // When
        self.sut.cancelPendingImport()

        // Then
        XCTAssertFalse(self.sut.showImportTypeSelection)
        XCTAssertNil(self.sut.pendingImportURL)
        XCTAssertFalse(self.sut.shouldStopMeditation)
    }

    // MARK: - Import Result State

    func testImportAsSoundscape_setsPendingCustomAudioImport() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/nature-sounds.mp3")
        self.sut.prepareImport(url: url)

        // When
        let result = await self.sut.importFile(from: url, as: .soundscape)

        // Then
        guard case .success = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertNotNil(self.sut.pendingCustomAudioImport)
        XCTAssertEqual(self.sut.pendingCustomAudioImport?.type, .soundscape)
    }

    func testImportAsAttunement_setsPendingCustomAudioImport() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/intro.m4a")
        self.sut.prepareImport(url: url)

        // When
        let result = await self.sut.importFile(from: url, as: .attunement)

        // Then
        guard case .success = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertNotNil(self.sut.pendingCustomAudioImport)
        XCTAssertEqual(self.sut.pendingCustomAudioImport?.type, .attunement)
    }

    func testImportAsGuidedMeditation_setsImportedMeditation() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = await self.sut.importFile(from: url, as: .guidedMeditation)

        // Then
        guard case .success = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertNotNil(self.sut.importedMeditation)
    }

    func testImportAsGuidedMeditation_doesNotSetPendingCustomAudio() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        _ = await self.sut.importFile(from: url, as: .guidedMeditation)

        // Then
        XCTAssertNil(self.sut.pendingCustomAudioImport)
    }
}
