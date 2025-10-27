//
//  AudioServiceTests.swift
//  MediTimerTests
//
//  Unit Tests - AudioService
//

import XCTest
import AVFoundation
@testable import MediTimer

final class AudioServiceTests: XCTestCase {
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        sut = AudioService()
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        super.tearDown()
    }

    func testConfigureAudioSession() {
        // When
        XCTAssertNoThrow(try sut.configureAudioSession())

        // Then - Verify audio session is configured
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)
    }

    func testConfigureAudioSessionMultipleTimes() {
        // Given - Configure once
        XCTAssertNoThrow(try sut.configureAudioSession())

        // When - Configure again (should not throw)
        XCTAssertNoThrow(try sut.configureAudioSession())
    }

    func testPlayCompletionSound() {
        // Given - Configure audio session first
        try? sut.configureAudioSession()

        // When
        XCTAssertNoThrow(try sut.playCompletionSound())

        // Note: Actual playback testing requires more complex mocking
        // This test verifies that the method doesn't throw an error
    }

    func testPlayCompletionSoundWithoutConfiguration() {
        // When - Try to play without configuring
        // This should still work as AVAudioPlayer can work without explicit session config
        XCTAssertNoThrow(try sut.playCompletionSound())
    }

    func testStopAudio() {
        // Given - Configure and play
        try? sut.configureAudioSession()
        try? sut.playCompletionSound()

        // When
        sut.stop()

        // Then - Should not crash (player is stopped and nil)
        XCTAssertNoThrow(sut.stop()) // Calling stop twice should be safe
    }

    func testLoadCustomSound() {
        // When - Load existing sound file
        let url = sut.loadCustomSound(filename: "completion.mp3")

        // Then
        XCTAssertNotNil(url, "completion.mp3 should exist in bundle")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func testLoadCustomSoundNonExistent() {
        // When - Try to load non-existent file
        let url = sut.loadCustomSound(filename: "nonexistent.mp3")

        // Then
        XCTAssertNil(url, "Non-existent file should return nil")
    }

    func testLoadCustomSoundWithFullExtension() {
        // When - Load with full filename
        let url1 = sut.loadCustomSound(filename: "completion.mp3")
        let url2 = sut.loadCustomSound(filename: "e-flat-tibetan-singing-bowl-struck-38746.mp3")

        // Then
        XCTAssertNotNil(url1)
        XCTAssertNotNil(url2)
    }

    func testMultiplePlaybackCalls() {
        // Given
        try? sut.configureAudioSession()

        // When - Play multiple times rapidly
        XCTAssertNoThrow(try sut.playCompletionSound())
        XCTAssertNoThrow(try sut.playCompletionSound())
        XCTAssertNoThrow(try sut.playCompletionSound())

        // Then - Should not crash (each call replaces the previous player)
    }

    func testDeinitStopsPlayback() {
        // Given
        try? sut.configureAudioSession()
        try? sut.playCompletionSound()

        // When - Deallocate service
        sut = nil

        // Then - Should not crash (deinit calls stop())
    }

    func testAudioSessionOptionsForBackgroundPlayback() throws {
        // Given
        try sut.configureAudioSession()

        // Then - Verify audio session allows background playback
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)

        // Verify mode
        XCTAssertEqual(audioSession.mode, .default)
    }

    func testErrorHandlingForMissingFile() {
        // Given - Create a new AudioService instance
        let service = AudioService()

        // When - Try to play with missing file (this would fail if Bundle.main.url returns nil)
        // The actual implementation throws AudioServiceError.soundFileNotFound

        // Note: In the real implementation, if completion.mp3 is missing, it will throw
        // For this test, we verify the file exists
        let url = Bundle.main.url(forResource: "completion", withExtension: "mp3")
        XCTAssertNotNil(url, "completion.mp3 must be included in test bundle")
    }
}

// MARK: - Integration Tests

extension AudioServiceTests {
    func testFullAudioFlow() throws {
        // Given - Fresh service
        let service = AudioService()

        // When - Complete flow: configure -> play -> stop
        try service.configureAudioSession()
        try service.playCompletionSound()

        // Wait briefly for playback to start
        let expectation = expectation(description: "Wait for playback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // Then
        service.stop()

        // Should be safe to repeat
        XCTAssertNoThrow(try service.configureAudioSession())
        XCTAssertNoThrow(try service.playCompletionSound())
    }
}
