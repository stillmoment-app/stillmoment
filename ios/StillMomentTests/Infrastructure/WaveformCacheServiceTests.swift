//
//  WaveformCacheServiceTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class WaveformCacheServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WaveformCacheTests-\(UUID().uuidString)")
        self.tempDirectory = directory
        self.sut = WaveformCacheService(directory: directory)
    }

    override func tearDownWithError() throws {
        if let tempDirectory, FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        self.sut = nil
        self.tempDirectory = nil
        try super.tearDownWithError()
    }

    func testSaveThenLoadReturnsSameWaveform() throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let id = UUID()
        let waveform = MeditationWaveform(samples: [0, 0.5, 1.0])

        // When
        try sut.save(id: id, waveform: waveform)
        let loaded = sut.load(id: id)

        // Then
        XCTAssertEqual(loaded, waveform)
    }

    func testLoadMissingReturnsNil() throws {
        // Given: nothing saved
        let sut = try XCTUnwrap(self.sut)

        // When
        let loaded = sut.load(id: UUID())

        // Then
        XCTAssertNil(loaded)
    }

    func testDeleteRemovesStoredWaveform() throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let id = UUID()
        try sut.save(id: id, waveform: MeditationWaveform(samples: [0.3]))
        XCTAssertNotNil(sut.load(id: id))

        // When
        sut.delete(id: id)

        // Then
        XCTAssertNil(sut.load(id: id))
    }

    func testDeleteMissingDoesNotThrowOrCrash() throws {
        // Given: nothing saved
        let sut = try XCTUnwrap(self.sut)

        // When / Then: delete is a safe no-op
        sut.delete(id: UUID())
    }

    func testSaveCreatesDirectoryIfNeeded() throws {
        // Given: directory does not exist yet
        let sut = try XCTUnwrap(self.sut)
        let directory = try XCTUnwrap(self.tempDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))

        // When
        try sut.save(id: UUID(), waveform: MeditationWaveform(samples: [1.0]))

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }

    // MARK: Private

    private var sut: WaveformCacheService?
    private var tempDirectory: URL?
}
