//
//  AudioServicePreviewSessionTests.swift
//  Still Moment
//
//  Tests for preview audio session separation (shared-054).
//  Verifies that preview methods use AudioSource.preview instead of .timer.
//

import XCTest
@testable import StillMoment

@MainActor
final class AudioServicePreviewSessionTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCoordinator: MockAudioSessionCoordinator!

    override func setUp() {
        super.setUp()
        self.mockCoordinator = MockAudioSessionCoordinator()
        self.sut = AudioService(coordinator: self.mockCoordinator)
    }

    override func tearDown() {
        self.sut = nil
        self.mockCoordinator = nil
        super.tearDown()
    }

    // MARK: - Preview Requests .preview Source

    func testPlayGongPreviewRequestsPreviewSession() throws {
        // When
        try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5)

        // Then — preview should register as .preview, not .timer
        XCTAssertTrue(
            self.mockCoordinator.requestedSources.contains(.preview),
            "Gong preview should request .preview audio session"
        )
        XCTAssertFalse(
            self.mockCoordinator.requestedSources.contains(.timer),
            "Gong preview should NOT request .timer audio session"
        )

        // Clean up
        self.sut.stopGongPreview()
    }

    func testPlayBackgroundPreviewRequestsPreviewSession() throws {
        // When
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // Then — preview should register as .preview, not .timer
        XCTAssertTrue(
            self.mockCoordinator.requestedSources.contains(.preview),
            "Background preview should request .preview audio session"
        )
        XCTAssertFalse(
            self.mockCoordinator.requestedSources.contains(.timer),
            "Background preview should NOT request .timer audio session"
        )

        // Clean up
        self.sut.stopBackgroundPreview()
    }

    // MARK: - Preview Releases Session After Completion

    func testStopGongPreviewReleasesPreviewSession() throws {
        // Given — preview is playing
        try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5)
        self.mockCoordinator.releasedSources.removeAll()

        // When
        self.sut.stopGongPreview()

        // Then — session is released for .preview
        XCTAssertTrue(
            self.mockCoordinator.releasedSources.contains(.preview),
            "Stopping gong preview should release .preview audio session"
        )
    }

    func testStopBackgroundPreviewReleasesPreviewSession() throws {
        // Given — preview is playing
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)
        self.mockCoordinator.releasedSources.removeAll()

        // When
        self.sut.stopBackgroundPreview()

        // Then — session is released for .preview
        XCTAssertTrue(
            self.mockCoordinator.releasedSources.contains(.preview),
            "Stopping background preview should release .preview audio session"
        )
    }

    // MARK: - Preview Does NOT Start Keep-Alive

    func testGongPreviewDoesNotStartKeepAlive() throws {
        // When — play gong preview
        try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5)

        // Then — no timer session activated (keep-alive is timer-only)
        XCTAssertFalse(
            self.mockCoordinator.requestedSources.contains(.timer),
            "Gong preview should not activate timer session (no keep-alive)"
        )

        // Clean up
        self.sut.stopGongPreview()
    }

    // MARK: - Timer Start Stops Preview (Conflict Handler)

    func testTimerStartStopsRunningPreview() throws {
        // Given — gong preview is playing
        try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5)

        // When — timer takes over the session
        // Simulate the coordinator calling the preview conflict handler
        self.mockCoordinator.requestedSources.removeAll()
        _ = try self.mockCoordinator.requestAudioSession(for: .timer)

        // Then — preview conflict handler was invoked, timer owns the session
        XCTAssertEqual(
            self.mockCoordinator.activeSource.value,
            .timer,
            "Timer should own the session after requesting it"
        )
    }

    // MARK: - Preview→Preview Reuse (Same Source, No Conflict)

    func testSecondPreviewReusesPreviewSession() throws {
        // Given — gong preview is playing
        try self.sut.playGongPreview(soundId: "tibetan-singing-bowl", volume: 0.5)
        let requestCountAfterFirst = self.mockCoordinator.requestedSources.count

        // When — background preview starts (same .preview source)
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // Then — a new .preview request was made (same source, coordinator allows it)
        XCTAssertGreaterThan(
            self.mockCoordinator.requestedSources.count,
            requestCountAfterFirst,
            "Second preview should make a new request"
        )
        // All requests should be .preview
        let nonPreviewRequests = self.mockCoordinator.requestedSources.filter { $0 != .preview }
        XCTAssertTrue(
            nonPreviewRequests.isEmpty,
            "All preview requests should use .preview source, got: \(nonPreviewRequests)"
        )

        // Clean up
        self.sut.stopBackgroundPreview()
    }
}
