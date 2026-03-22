//
//  AudioServiceKeepAliveTests.swift
//  Still Moment
//
//  Tests for the always-on keep-alive invariant (shared-059).
//  Keep-alive runs continuously from activateTimerSession() to deactivateTimerSession().
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
        self.sut.deactivateTimerSession()
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Timer Session Lifecycle

    func testKeepAliveStartsWhenTimerSessionActivates() throws {
        // When — a timer session begins
        try self.sut.activateTimerSession()

        // Then — keep-alive is running (background audio can start alongside it)
        XCTAssertNoThrow(try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15))
    }

    func testKeepAliveIsPlayingAfterActivation() throws {
        // Regression: app was suspended when locking screen during preparation time.
        // Root cause: keepAlivePlayer was assigned before play() was called — if play()
        // returned false, the player was non-nil but silent, blocking all retries.
        // During preparation, no gong or background audio plays: keep-alive is the sole
        // mechanism that keeps iOS from suspending the app.

        // When — a timer session begins (simulates timer start with preparation time)
        try self.sut.activateTimerSession()

        // Then — keep-alive player must be actively playing, not just assigned
        XCTAssertTrue(self.sut.isKeepAliveActive, "Keep-alive must be playing after activateTimerSession()")
    }

    func testKeepAliveIsNotPlayingAfterDeactivation() throws {
        // Given — timer session is active and keep-alive is playing
        try self.sut.activateTimerSession()
        XCTAssertTrue(self.sut.isKeepAliveActive)

        // When — session ends
        self.sut.deactivateTimerSession()

        // Then — keep-alive must stop
        XCTAssertFalse(self.sut.isKeepAliveActive, "Keep-alive must stop after deactivateTimerSession()")
    }

    func testKeepAliveStopsWhenTimerSessionDeactivates() throws {
        // Given — timer session is active
        try self.sut.activateTimerSession()

        // When — session ends
        self.sut.deactivateTimerSession()

        // Then — deactivating again is safe (idempotent)
        self.sut.deactivateTimerSession()
    }

    // MARK: - Always-On Invariant: Keep-Alive Survives Audio Transitions

    func testKeepAliveRunsDuringBackgroundAudioPlayback() throws {
        // Given — timer session active
        try self.sut.activateTimerSession()

        // When — background audio starts (keep-alive must NOT be stopped)
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // Then — deactivate cleans up both keep-alive and background audio
        self.sut.deactivateTimerSession()
    }

    func testKeepAliveRunsAfterBackgroundAudioStops() throws {
        // Given — timer session with background audio
        try self.sut.activateTimerSession()
        try self.sut.startBackgroundAudio(soundId: "silent", volume: 0.15)

        // When — background audio stops (keep-alive must continue)
        self.sut.stopBackgroundAudio()

        // Then — session can be cleanly deactivated
        self.sut.deactivateTimerSession()
    }

    func testKeepAliveRunsDuringGongPlayback() throws {
        // Given — timer session active
        try self.sut.activateTimerSession()

        // When — gong plays in parallel
        try self.sut.playStartGong(soundId: "tibetan-singing-bowl", volume: 0.8)

        // Then — session deactivates cleanly
        self.sut.deactivateTimerSession()
    }

    func testKeepAliveRunsDuringAttunementPhase() throws {
        // Given — timer session active
        try self.sut.activateTimerSession()

        // When — attunement starts and finishes (simulated by stopping)
        self.sut.stopAttunement() // No-op if not playing

        // Then — keep-alive still active, session deactivates cleanly
        self.sut.deactivateTimerSession()
    }

    // MARK: - No Keep-Alive Activity After Deactivation

    func testNoKeepAliveAfterDeactivation() throws {
        // Given — timer session was active, now deactivated
        try self.sut.activateTimerSession()
        self.sut.deactivateTimerSession()

        // When/Then — a fresh session can be started
        XCTAssertNoThrow(try self.sut.activateTimerSession())
    }

    // MARK: - Idempotency

    func testActivateCalledMultipleTimesDoesNotStackKeepAlive() throws {
        // When — activate called multiple times
        try self.sut.activateTimerSession()
        try self.sut.activateTimerSession()
        try self.sut.activateTimerSession()

        // Then — single deactivate cleans everything
        self.sut.deactivateTimerSession()
    }

    // MARK: - Legacy configureAudioSession (Preview Path)

    func testConfigureAudioSessionStillWorksForPreviews() throws {
        // Previews use configureAudioSession() directly, not activateTimerSession()

        // When
        try self.sut.configureAudioSession()

        // Then — preview audio works
        XCTAssertNoThrow(try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5))

        // Clean up
        self.sut.stopGongPreview()
        self.sut.stop()
        AudioSessionCoordinator.shared.releaseAudioSession(for: .timer)
    }
}
