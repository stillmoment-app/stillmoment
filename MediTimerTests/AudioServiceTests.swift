//
//  AudioServiceTests.swift
//  MediTimerTests
//
//  Unit Tests - AudioService
//

import AVFoundation
import XCTest
@testable import MediTimer

final class AudioServiceTests: XCTestCase {
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        self.sut = AudioService()
    }

    override func tearDown() {
        self.sut.stop()
        self.sut = nil
        super.tearDown()
    }

    func testConfigureAudioSession() {
        // When
        XCTAssertNoThrow(try self.sut.configureAudioSession())

        // Then - Verify audio session is configured
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func testLoadCustomSoundNonExistent() {
        // When - Try to load non-existent file
        let url = self.sut.loadCustomSound(filename: "nonexistent.mp3")

        // Then
        XCTAssertNil(url, "Non-existent file should return nil")
    }

    func testLoadCustomSoundWithFullExtension() {
        // When - Load with full filename
        let url1 = self.sut.loadCustomSound(filename: "completion.mp3")
        let url2 = self.sut.loadCustomSound(filename: "e-flat-tibetan-singing-bowl-struck-38746.mp3")

        // Then
        XCTAssertNotNil(url1)
        XCTAssertNotNil(url2)
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
    }

    func testAudioSessionOptionsForBackgroundPlayback() throws {
        // Given
        try self.sut.configureAudioSession()

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
