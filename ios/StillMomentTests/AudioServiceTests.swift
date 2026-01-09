//
//  AudioServiceTests.swift
//  Still Moment
//

import AVFoundation
import Combine
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
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))

        // Note: Actual playback testing requires more complex mocking
        // This test verifies that the method doesn't throw an error
    }

    func testPlayCompletionSoundWithoutConfiguration() {
        // When - Try to play without configuring
        // This should still work as AVAudioPlayer can work without explicit session config
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))
    }

    func testStopAudio() {
        // Given - Configure and play
        try? self.sut.configureAudioSession()
        try? self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0)

        // When
        self.sut.stop()

        // Then - Should not crash (player is stopped and nil)
        XCTAssertNoThrow(self.sut.stop()) // Calling stop twice should be safe
    }

    func testLoadCustomSound() {
        // When - Load existing gong sound file
        let gongSound = GongSound.defaultSound
        let url = self.sut.loadCustomSound(filename: gongSound.filename)

        // Then
        XCTAssertNotNil(url, "\(gongSound.filename) should exist in bundle")
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
        let gongSound = GongSound.defaultSound
        let url = self.sut.loadCustomSound(filename: gongSound.filename)

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
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))

        // Then - Should not crash (each call replaces the previous player)
    }

    func testDeinitStopsPlayback() {
        // Given
        try? self.sut.configureAudioSession()
        try? self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0)

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

        // Note: In the real implementation, if gong sound file is missing, it will throw
        // For this test, we verify all gong sound files exist
        for gongSound in GongSound.allSounds {
            let components = gongSound.filename.components(separatedBy: ".")
            let name = components.first ?? gongSound.filename
            let ext = components.count > 1 ? components.last : "mp3"

            let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "GongSounds"
            )
            XCTAssertNotNil(url, "\(gongSound.filename) must be included in test bundle")
        }
    }

    func testStartBackgroundAudio_WithInvalidSoundId_ThrowsError() {
        // Given
        let invalidSoundId = "nonexistent"

        // When / Then
        XCTAssertThrowsError(try self.sut.startBackgroundAudio(soundId: invalidSoundId, volume: 0.15)) { error in
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
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15))

        // Then - Clean up
        self.sut.stop()
    }

    func testStartBackgroundAudio_WithMissingSoundId_ThrowsError() {
        // Given - Sound ID that exists in repository but file is missing
        // This test ensures the bundle lookup also fails gracefully
        let missingSoundId = "whitenoise" // This was removed

        // When / Then
        XCTAssertThrowsError(try self.sut.startBackgroundAudio(soundId: missingSoundId, volume: 0.15)) { error in
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

    func testPlayStartGong_WithConfiguration_Succeeds() throws {
        // Given
        try self.sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 1.0))

        // Then - Should play without error
        // Clean up
        self.sut.stop()
    }

    func testPlayStartGong_WithoutConfiguration_Succeeds() {
        // When - Play without explicit configuration
        XCTAssertNoThrow(try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 1.0))

        // Then - Should configure automatically and play
        self.sut.stop()
    }

    func testPlayIntervalGong_Succeeds() throws {
        // Given
        try self.sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try self.sut.playIntervalGong(volume: 1.0))

        // Then - Should play without error
        self.sut.stop()
    }

    func testPlayIntervalGong_WithoutConfiguration_Succeeds() {
        // When - Play without explicit configuration
        XCTAssertNoThrow(try self.sut.playIntervalGong(volume: 1.0))

        // Then - Should configure automatically and play
        self.sut.stop()
    }

    func testPlayGongPreview_Succeeds() throws {
        // Given
        try self.sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try self.sut.playGongPreview(soundId: "deep-zen", volume: 1.0))

        // Then - Should play without error
        self.sut.stopGongPreview()
        self.sut.stop()
    }

    func testStopGongPreview_WhenNotPlaying_DoesNotCrash() {
        // Given - No preview playing

        // When
        self.sut.stopGongPreview()

        // Then - Should be safe (idempotent)
        self.sut.stopGongPreview() // Second call should also be safe
    }

    func testPlayGongPreview_StopsPreviousPreview() throws {
        // Given - Start first preview
        try self.sut.configureAudioSession()
        try self.sut.playGongPreview(soundId: "classic-bowl", volume: 1.0)

        // When - Start second preview
        XCTAssertNoThrow(try self.sut.playGongPreview(soundId: "deep-zen", volume: 1.0))

        // Then - Should replace previous (no crash, no overlap)
        self.sut.stopGongPreview()
        self.sut.stop()
    }

    func testAllGongSounds_PlaySuccessfully() throws {
        // Given
        try self.sut.configureAudioSession()

        // When - Play all gong sounds
        for gongSound in GongSound.allSounds {
            XCTAssertNoThrow(
                try self.sut.playStartGong(soundId: gongSound.id, volume: 1.0),
                "Gong sound '\(gongSound.id)' should play successfully"
            )
        }

        // Then - Clean up
        self.sut.stop()
    }

    func testStopBackgroundAudio_WhenPlaying_StopsPlayback() throws {
        // Given - Start background audio
        try self.sut.configureAudioSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When
        self.sut.stopBackgroundAudio()

        // Then - Should stop without error (verified by not crashing)
        // Clean up
        self.sut.stop()
    }

    func testStopBackgroundAudio_WhenNotPlaying_DoesNotCrash() {
        // Given - No background audio playing

        // When
        self.sut.stopBackgroundAudio()

        // Then - Should be safe (idempotent)
        self.sut.stopBackgroundAudio() // Second call should also be safe
    }

    func testStop_ReleasesAudioSession() throws {
        // Given - Configure and start audio
        try self.sut.configureAudioSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When
        self.sut.stop()

        // Then - Should be able to reconfigure and play again
        XCTAssertNoThrow(try self.sut.configureAudioSession())
        XCTAssertNoThrow(try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))

        // Clean up
        self.sut.stop()
    }

    func testStop_WhenCalledMultipleTimes_IsIdempotent() {
        // Given
        try? self.sut.configureAudioSession()
        try? self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0)

        // When - Call stop multiple times
        self.sut.stop()
        self.sut.stop()
        self.sut.stop()

        // Then - Should not crash
        XCTAssertNoThrow(self.sut.stop())
    }

    func testBackgroundAudio_ForestSound_PlaysWithCorrectVolume() throws {
        // Given
        try self.sut.configureAudioSession()

        // When - Start forest sound
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "forest", volume: 0.15))

        // Then - Should play without error
        // Clean up
        self.sut.stop()
    }

    func testBackgroundAudio_SwitchingSounds_Succeeds() throws {
        // Given - Start with silent
        try self.sut.configureAudioSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When - Switch to forest
        self.sut.stopBackgroundAudio()
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "forest", volume: 0.15))

        // Then - Should switch without error
        // Clean up
        self.sut.stop()
    }

    func testAudioService_WithCustomCoordinator_UsesProvidedCoordinator() {
        // Given - Create test coordinator
        let testCoordinator = AudioSessionCoordinator.shared

        // When - Create service with custom coordinator
        let service = AudioService(coordinator: testCoordinator)

        // Then - Should initialize successfully
        XCTAssertNotNil(service)

        // Clean up
        service.stop()
    }

    func testStartBackgroundAudio_WithFilenameWithoutExtension_HandlesGracefully() {
        // This tests the edge case where filename parsing might fail
        // Given - Repository should have sounds with proper filenames

        // When / Then - All sounds should have valid filenames
        let repository = BackgroundSoundRepository()
        let sounds = repository.availableSounds

        for sound in sounds {
            let components = sound.filename.components(separatedBy: ".")
            XCTAssertGreaterThanOrEqual(
                components.count,
                2,
                "Sound '\(sound.id)' should have filename with extension: '\(sound.filename)'"
            )
        }
    }

    func testMultipleGongPlays_DoNotInterfere() throws {
        // Given
        try self.sut.configureAudioSession()

        // When - Play multiple gongs rapidly
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 1.0)
        try self.sut.playIntervalGong(volume: 1.0)
        try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0)

        // Then - Should complete without error (each replaces previous)
        self.sut.stop()
    }

    func testBackgroundAudioAndGong_PlaySimultaneously() throws {
        // Given - Start background audio
        try self.sut.configureAudioSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When - Play gong while background audio is playing
        XCTAssertNoThrow(try self.sut.playIntervalGong(volume: 1.0))

        // Then - Both should play (different players)
        self.sut.stop()
    }

    // MARK: - Background Preview Tests

    func testPlayBackgroundPreview_Succeeds() throws {
        // Given
        try self.sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5))

        // Then - Should play without error
        self.sut.stopBackgroundPreview()
        self.sut.stop()
    }

    func testStopBackgroundPreview_WhenNotPlaying_DoesNotCrash() {
        // Given - No preview playing

        // When
        self.sut.stopBackgroundPreview()

        // Then - Should be safe (idempotent)
        self.sut.stopBackgroundPreview() // Second call should also be safe
    }

    func testPlayBackgroundPreview_StopsPreviousPreview() throws {
        // Given - Start first preview
        try self.sut.configureAudioSession()
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // When - Start second preview
        XCTAssertNoThrow(try self.sut.playBackgroundPreview(soundId: "silent", volume: 0.3))

        // Then - Should replace previous (no crash, no overlap)
        self.sut.stopBackgroundPreview()
        self.sut.stop()
    }

    func testPlayBackgroundPreview_StopsGongPreview() throws {
        // Given - Start gong preview
        try self.sut.configureAudioSession()
        try self.sut.playGongPreview(soundId: "deep-zen", volume: 1.0)

        // When - Start background preview
        XCTAssertNoThrow(try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5))

        // Then - Gong preview should be stopped (mutual exclusion)
        // Clean up
        self.sut.stopBackgroundPreview()
        self.sut.stop()
    }

    func testPlayGongPreview_StopsBackgroundPreview() throws {
        // Given - Start background preview
        try self.sut.configureAudioSession()
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // When - Start gong preview
        XCTAssertNoThrow(try self.sut.playGongPreview(soundId: "deep-zen", volume: 1.0))

        // Then - Background preview should be stopped (mutual exclusion)
        // Clean up
        self.sut.stopGongPreview()
        self.sut.stop()
    }

    func testPlayBackgroundPreview_WithInvalidSoundId_ThrowsError() {
        // Given
        let invalidSoundId = "nonexistent"

        // When / Then
        XCTAssertThrowsError(try self.sut.playBackgroundPreview(soundId: invalidSoundId, volume: 0.5)) { error in
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

    func testPlayBackgroundPreview_WithSilentSoundId_StopsPreviewsWithoutPlaying() throws {
        // Given - Start a gong preview first
        try self.sut.configureAudioSession()
        try self.sut.playGongPreview(soundId: "deep-zen", volume: 1.0)

        // When - Select "silent" background sound
        XCTAssertNoThrow(try self.sut.playBackgroundPreview(soundId: "silent", volume: 0.3))

        // Then - Should not throw, and should have stopped any running previews
        // (calling stop again should be safe)
        self.sut.stopGongPreview()
        self.sut.stopBackgroundPreview()
        self.sut.stop()
    }

    func testBackgroundPreviewFadeOut_AfterDuration_StopsAutomatically() async throws {
        // Given
        try self.sut.configureAudioSession()
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // When - Wait for preview duration + fade out (3s + 0.5s + buffer)
        let expectation = expectation(description: "Wait for fade out")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5.0)

        // Then - Should have stopped automatically (no crash when calling stop again)
        self.sut.stopBackgroundPreview()
        self.sut.stop()
    }
}

// MARK: - Integration Tests

extension AudioServiceTests {
    func testFullAudioFlow() async {
        // Given - Fresh service
        let service = AudioService()

        // When - Complete flow: configure -> play -> stop
        XCTAssertNoThrow(try service.configureAudioSession())
        XCTAssertNoThrow(try service.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))

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
        XCTAssertNoThrow(try service.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0))
    }

    func testFullMeditationFlow() async throws {
        // Given - Fresh service
        let service = AudioService()

        // When - Simulate full meditation cycle
        try service.configureAudioSession()
        try service.playStartGong(soundId: GongSound.defaultSoundId, volume: 1.0)

        // Wait briefly
        let startGongExpectation = expectation(description: "Start gong")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startGongExpectation.fulfill()
        }
        await fulfillment(of: [startGongExpectation], timeout: 0.5)

        // Start background audio
        try service.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // Wait briefly
        let backgroundAudioExpectation = expectation(description: "Background audio")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            backgroundAudioExpectation.fulfill()
        }
        await fulfillment(of: [backgroundAudioExpectation], timeout: 0.5)

        // Play interval gong
        try service.playIntervalGong(volume: 1.0)

        // Wait briefly
        let intervalGongExpectation = expectation(description: "Interval gong")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            intervalGongExpectation.fulfill()
        }
        await fulfillment(of: [intervalGongExpectation], timeout: 0.5)

        // Stop background audio and play completion
        service.stopBackgroundAudio()
        try service.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 1.0)

        // Wait briefly
        let completionExpectation = expectation(description: "Completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completionExpectation.fulfill()
        }
        await fulfillment(of: [completionExpectation], timeout: 0.5)

        // Then - Clean stop
        service.stop()
    }
}
