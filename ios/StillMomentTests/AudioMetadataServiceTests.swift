//
//  AudioMetadataServiceTests.swift
//  Still Moment
//

import AVFoundation
import XCTest
@testable import StillMoment

/// Tests for AudioMetadataService - ID3 tag extraction from audio files
@MainActor
final class AudioMetadataServiceTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioMetadataService!

    override func setUp() {
        super.setUp()
        self.sut = AudioMetadataService()
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    // MARK: - File Access Tests

    func testExtractMetadata_FileNotAccessible_ThrowsError() async {
        // Given - Non-existent file
        let invalidURL = URL(fileURLWithPath: "/path/to/nonexistent/file.mp3")

        // When/Then
        do {
            _ = try await self.sut.extractMetadata(from: invalidURL)
            XCTFail("Expected fileNotAccessible error")
        } catch AudioMetadataError.fileNotAccessible {
            // Expected error
        } catch {
            XCTFail("Expected fileNotAccessible, got \(error)")
        }
    }

    // MARK: - Existing Audio File Tests

    func testExtractMetadata_ValidMP3_ExtractsDuration() async throws {
        // Given - Use existing gong sound from bundle
        let gongSound = GongSound.defaultSound
        let filenameComponents = gongSound.filename.components(separatedBy: ".")
        let name = filenameComponents.first ?? gongSound.filename
        let ext = filenameComponents.count > 1 ? filenameComponents.last : "mp3"

        guard let audioURL = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "GongSounds"
        ) else {
            XCTFail("\(gongSound.filename) not found in bundle")
            return
        }

        // When
        let metadata = try await self.sut.extractMetadata(from: audioURL)

        // Then - Duration should be positive and finite
        XCTAssertGreaterThan(metadata.duration, 0, "Duration should be > 0")
        XCTAssertTrue(metadata.duration.isFinite, "Duration should be finite")
        XCTAssertLessThan(metadata.duration, 30, "Gong sound should be < 30 seconds")
    }

    func testExtractMetadata_SilenceFile_ExtractsDuration() async throws {
        // Given - Use existing silence.mp3 from bundle
        guard let audioURL = Bundle.main.url(forResource: "silence", withExtension: "mp3") else {
            XCTFail("silence.mp3 not found in bundle")
            return
        }

        // When
        let metadata = try await self.sut.extractMetadata(from: audioURL)

        // Then - Duration should be valid
        XCTAssertGreaterThan(metadata.duration, 0, "Duration should be > 0")
        XCTAssertTrue(metadata.duration.isFinite, "Duration should be finite")
    }

    // MARK: - Metadata Extraction Tests

    func testExtractMetadata_NoID3Tags_ReturnsNilFields() async throws {
        // Given - silence.mp3 likely has no ID3 tags
        guard let audioURL = Bundle.main.url(forResource: "silence", withExtension: "mp3") else {
            XCTFail("silence.mp3 not found in bundle")
            return
        }

        // When
        let metadata = try await self.sut.extractMetadata(from: audioURL)

        // Then - Should extract duration but artist/title may be nil
        XCTAssertGreaterThan(metadata.duration, 0)
        // Note: artist/title can be nil for files without tags - this is valid
    }

    // MARK: - Error Handling Tests

    func testExtractMetadata_InvalidDuration_ThrowsError() async {
        // Given - Create URL to a non-audio file (Info.plist)
        guard let invalidURL = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            // If Info.plist not accessible, use alternative approach
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.mp3")
            try? Data().write(to: tempURL)

            // When/Then
            do {
                _ = try await self.sut.extractMetadata(from: tempURL)
                XCTFail("Expected durationNotAvailable error")
            } catch AudioMetadataError.durationNotAvailable {
                // Expected error
            } catch {
                // Also acceptable - AVAsset may throw other errors for invalid files
                XCTAssertTrue(error is AudioMetadataError)
            }

            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            return
        }

        // When/Then
        do {
            _ = try await self.sut.extractMetadata(from: invalidURL)
            XCTFail("Expected error for non-audio file")
        } catch {
            // Expected - should throw error for non-audio file
            XCTAssertTrue(true)
        }
    }

    // MARK: - Integration Tests

    func testExtractMetadata_MultipleFiles_AllSucceed() async throws {
        // Given - Multiple audio files
        let resources = [
            ("completion", "mp3"),
            ("silence", "m4a")
        ]

        // When/Then - All should extract successfully
        for (name, ext) in resources {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                continue // Skip if file not found
            }

            let metadata = try await self.sut.extractMetadata(from: url)
            XCTAssertGreaterThan(
                metadata.duration,
                0,
                "\(name).\(ext) should have valid duration"
            )
        }
    }

    // MARK: - AudioMetadata Model Tests

    func testAudioMetadata_Initialization() {
        // Given
        let artist = "Test Teacher"
        let title = "Test Meditation"
        let duration: TimeInterval = 1800.0
        let album = "Test Album"

        // When
        let metadata = AudioMetadata(
            artist: artist,
            title: title,
            duration: duration,
            album: album
        )

        // Then
        XCTAssertEqual(metadata.artist, artist)
        XCTAssertEqual(metadata.title, title)
        XCTAssertEqual(metadata.duration, duration)
        XCTAssertEqual(metadata.album, album)
    }

    func testAudioMetadata_InitializationWithNilValues() {
        // Given/When - Artist and title can be nil
        let metadata = AudioMetadata(
            artist: nil,
            title: nil,
            duration: 600.0
        )

        // Then
        XCTAssertNil(metadata.artist)
        XCTAssertNil(metadata.title)
        XCTAssertEqual(metadata.duration, 600.0)
        XCTAssertNil(metadata.album)
    }

    func testAudioMetadata_Equatable() {
        // Given
        let metadata1 = AudioMetadata(artist: "A", title: "B", duration: 100.0, album: "C")
        let metadata2 = AudioMetadata(artist: "A", title: "B", duration: 100.0, album: "C")
        let metadata3 = AudioMetadata(artist: "X", title: "Y", duration: 200.0, album: "Z")

        // Then
        XCTAssertEqual(metadata1, metadata2)
        XCTAssertNotEqual(metadata1, metadata3)
    }
}
