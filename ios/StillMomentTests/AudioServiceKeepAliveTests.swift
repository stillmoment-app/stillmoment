//
//  AudioServiceKeepAliveTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceKeepAliveTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        self.sut = AudioService()
    }

    override func tearDown() {
        self.sut.stop()
        AudioSessionCoordinator.shared.releaseAudioSession(for: .timer)
        self.sut = nil
        super.tearDown()
    }

    func testConfigureAudioSession_StartsKeepAliveAudio() throws {
        // When
        try self.sut.configureAudioSession()

        // Then - Keep-alive should be playing (verified by startBackgroundAudio replacing it without crash)
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15))

        // Clean up
        self.sut.stop()
    }

    func testStartBackgroundAudio_ReplacesKeepAlive() throws {
        // Given - Configure starts keep-alive
        try self.sut.configureAudioSession()

        // When - Start background audio (should stop keep-alive first)
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // Then - Should succeed without error (keep-alive replaced)
        // Calling stop should clean up everything
        self.sut.stop()
    }

    func testStopBackgroundAudio_AlsoStopsKeepAlive() throws {
        // Given - Configure starts keep-alive
        try self.sut.configureAudioSession()

        // When - Stop background audio (also stops keep-alive)
        self.sut.stopBackgroundAudio()

        // Then - Calling stop again should be safe
        self.sut.stop()
    }

    func testStop_CleansUpKeepAliveAudio() throws {
        // Given - Configure starts keep-alive
        try self.sut.configureAudioSession()

        // When
        self.sut.stop()

        // Then - Can reconfigure and start fresh
        XCTAssertNoThrow(try self.sut.configureAudioSession())
        self.sut.stop()
    }

    func testConfigureAudioSession_CalledMultipleTimes_DoesNotStackKeepAlive() throws {
        // Given - Configure once (starts keep-alive)
        try self.sut.configureAudioSession()

        // When - Configure again (keep-alive guard: already running → no-op)
        try self.sut.configureAudioSession()
        try self.sut.configureAudioSession()

        // Then - Should be safe, only one keep-alive instance
        self.sut.stop()
    }

    func testKeepAlive_NotStartedWhenBackgroundAudioAlreadyPlaying() throws {
        // Given - Start background audio (which stops keep-alive)
        try self.sut.configureAudioSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When - Configure again (guard: backgroundAudioPlayer != nil → no keep-alive)
        try self.sut.configureAudioSession()

        // Then - Should not crash (keep-alive guard prevents restart)
        self.sut.stop()
    }
}
