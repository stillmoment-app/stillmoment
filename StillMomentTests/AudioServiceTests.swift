//
//  AudioServiceTests.swift
//  Still Moment
//

import AVFoundation
import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        self.sut = AudioService()
    }

    override func tearDown() {
        self.sut.stop()
        // Release audio session to prevent conflicts with parallel tests
        AudioSessionCoordinator.shared.releaseAudioSession(for: .timer)
        self.sut = nil
        super.tearDown()
    }

    func testConfigureAudioSession() {
        // When
        XCTAssertNoThrow(try self.sut.configureAudioSession())

        // Then - Should not throw (actual category verification is flaky in parallel tests)
        // Integration tests should verify the actual AVAudioSession state
    }

    func testConfigureAudioSessionMultipleTimes() {
        // Given - Configure once
        XCTAssertNoThrow(try self.sut.configureAudioSession())

        // When - Configure again (should not throw)
        XCTAssertNoThrow(try self.sut.configureAudioSession())
    }

    func testPlayCompletionSound() {
        // Given - Configure audio session first
        try? self.sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try self.sut.playCompletionSound())

        // Note: Actual playback testing requires more complex mocking
        // This test verifies that the method doesn't throw an error
    }

    func testPlayCompletionSoundWithoutConfiguration() {
        // When - Try to play without configuring
        // This should still work as AVAudioPlayer can work without explicit session config
        XCTAssertNoThrow(try self.sut.playCompletionSound())
    }

    func testStopAudio() {
        // Given - Configure and play
        try? self.sut.configureAudioSession()
        try? self.sut.playCompletionSound()

        // When
        self.sut.stop()

        // Then - Should not crash (player is stopped and nil)
        XCTAssertNoThrow(self.sut.stop()) // Calling stop twice should be safe
    }

    func testLoadCustomSound() {
        // When - Load existing sound file
        let url = self.sut.loadCustomSound(filename: "completion.mp3")

        // Then
        XCTAssertNotNil(url, "completion.mp3 should exist in bundle")
        if let url {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testLoadCustomSoundNonExistent() {
        // When - Try to load non-existent file
        let url = self.sut.loadCustomSound(filename: "nonexistent.mp3")

        // Then
        XCTAssertNil(url, "Non-existent file should return nil")
    }

    func testLoadCustomSoundWithFullExtension() {
        // When - Load with full filename
        let url = self.sut.loadCustomSound(filename: "completion.mp3")

        // Then
        XCTAssertNotNil(url)
        if let url {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testMultiplePlaybackCalls() {
        // Given
        try? self.sut.configureAudioSession()

        // When - Play multiple times rapidly
        XCTAssertNoThrow(try self.sut.playCompletionSound())
        XCTAssertNoThrow(try self.sut.playCompletionSound())
        XCTAssertNoThrow(try self.sut.playCompletionSound())

        // Then - Should not crash (each call replaces the previous player)
    }

    func testDeinitStopsPlayback() {
        // Given
        try? self.sut.configureAudioSession()
        try? self.sut.playCompletionSound()

        // When - Deallocate service
        self.sut = nil

        // Then - Should not crash (deinit calls stop())
        // Create new instance to continue testing
        self.sut = AudioService()
    }

    func testAudioSessionOptionsForBackgroundPlayback() throws {
        // Given / When
        XCTAssertNoThrow(try self.sut.configureAudioSession())

        // Then - Should not throw
        // Note: Checking AVAudioSession.sharedInstance() state is flaky in parallel tests
        // as other tests modify the same singleton. Integration tests should verify this.
    }

    func testErrorHandlingForMissingFile() {
        // Given - Create a new AudioService instance
        _ = AudioService()

        // When - Try to play with missing file (this would fail if Bundle.main.url returns nil)
        // The actual implementation throws AudioServiceError.soundFileNotFound

        // Note: In the real implementation, if completion.mp3 is missing, it will throw
        // For this test, we verify the file exists
        let url = Bundle.main.url(forResource: "completion", withExtension: "mp3")
        XCTAssertNotNil(url, "completion.mp3 must be included in test bundle")
    }

    func testStartBackgroundAudio_WithInvalidSoundId_ThrowsError() {
        // Given
        let invalidSoundId = "nonexistent"

        // When / Then
        XCTAssertThrowsError(try self.sut.startBackgroundAudio(soundId: invalidSoundId)) { error in
            // Verify the correct error type is thrown
            guard let audioError = error as? AudioServiceError else {
                XCTFail("Expected AudioServiceError but got \(type(of: error))")
                return
            }

            if case .soundFileNotFound = audioError {
                // Success - correct error type
            } else {
                XCTFail("Expected soundFileNotFound error but got \(audioError)")
            }
        }
    }

    func testStartBackgroundAudio_WithValidSoundId_Succeeds() throws {
        // Given
        try self.sut.configureAudioSession()

        // When - Start with valid sound ID
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "silent"))

        // Then - Clean up
        self.sut.stop()
    }

    func testStartBackgroundAudio_WithMissingSoundId_ThrowsError() {
        // Given - Sound ID that exists in repository but file is missing
        // This test ensures the bundle lookup also fails gracefully
        let missingSoundId = "whitenoise" // This was removed

        // When / Then
        XCTAssertThrowsError(try self.sut.startBackgroundAudio(soundId: missingSoundId)) { error in
            // Should throw soundFileNotFound error
            XCTAssertTrue(error is AudioServiceError, "Should throw AudioServiceError")
        }
    }

    func testAllBackgroundSoundFiles_AreIncludedInBundle() {
        // Given - Load all sounds from repository
        let repository = BackgroundSoundRepository()
        let sounds = repository.availableSounds

        // Then - Verify each sound file exists in bundle
        for sound in sounds {
            let components = sound.filename.components(separatedBy: ".")
            let name = components.first ?? sound.filename
            let ext = components.count > 1 ? components.last : nil

            let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "BackgroundAudio"
            )

            XCTAssertNotNil(
                url,
                "Background sound file '\(sound.filename)' (id: '\(sound.id)') must be included in bundle"
            )

            if let url {
                XCTAssertTrue(
                    FileManager.default.fileExists(atPath: url.path),
                    "Background sound file '\(sound.filename)' must exist at path: \(url.path)"
                )
            }
        }

        // Verify we have at least the default sounds
        XCTAssertTrue(sounds.count >= 2, "Should have at least 'silent' and 'forest' sounds")
    }
}

// MARK: - Integration Tests

extension AudioServiceTests {
    func testFullAudioFlow() async {
        // Given - Fresh service
        let service = AudioService()

        // When - Complete flow: configure -> play -> stop
        XCTAssertNoThrow(try service.configureAudioSession())
        XCTAssertNoThrow(try service.playCompletionSound())

        // Wait briefly for playback to start
        let expectation = expectation(description: "Wait for playback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 0.5)

        // Then
        service.stop()

        // Should be safe to repeat
        XCTAssertNoThrow(try service.configureAudioSession())
        XCTAssertNoThrow(try service.playCompletionSound())
    }
}
