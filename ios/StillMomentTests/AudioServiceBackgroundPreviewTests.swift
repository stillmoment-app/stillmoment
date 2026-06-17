//
//  AudioServiceBackgroundPreviewTests.swift
//  Still Moment
//
//  Tests for the looping background preview behaviour (shared-121):
//  the preview loops until explicitly stopped (no auto fade-out) and its
//  volume can be changed live without a restart.
//

import AVFoundation
import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceBackgroundPreviewTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!

    override func setUp() {
        super.setUp()
        self.sut = AudioService(
            coordinator: AudioSessionCoordinator.shared,
            fadeOutDuration: 0.05
        )
    }

    override func tearDown() {
        self.sut.stop()
        AudioSessionCoordinator.shared.releaseAudioSession(for: .preview)
        AudioSessionCoordinator.shared.releaseAudioSession(for: .timer)
        self.sut = nil
        super.tearDown()
    }

    func testBackgroundPreview_LoopsUntilExplicitStop() async throws {
        // Given — a background preview is started (loops, no auto-fade)
        try self.sut.configureAudioSession()
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // When — waiting well past the former 3s auto-fade window
        let expectation = expectation(description: "Wait past former auto-fade window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 0.5)

        // Then — the preview is still playing (did not auto-stop)
        XCTAssertTrue(
            self.sut.isBackgroundPreviewPlaying,
            "Background preview must loop until explicitly stopped"
        )

        self.sut.stopBackgroundPreview()
        XCTAssertFalse(
            self.sut.isBackgroundPreviewPlaying,
            "Background preview should stop on explicit stop"
        )
    }

    func testSetBackgroundPreviewVolume_ChangesRunningPreviewLevel() throws {
        // Given — a background preview is running
        try self.sut.configureAudioSession()
        try self.sut.playBackgroundPreview(soundId: "forest", volume: 0.5)

        // When — the level is changed live
        self.sut.setBackgroundPreviewVolume(0.9)

        // Then — the running preview reflects the new level (no restart, still playing)
        XCTAssertEqual(self.sut.backgroundPreviewVolume, 0.9, accuracy: 0.001)
        XCTAssertTrue(self.sut.isBackgroundPreviewPlaying)

        self.sut.stopBackgroundPreview()
    }

    func testSetBackgroundPreviewVolume_NoActivePreview_IsNoOp() {
        // Given — no preview running
        // When / Then — does not crash
        self.sut.setBackgroundPreviewVolume(0.7)
        XCTAssertFalse(self.sut.isBackgroundPreviewPlaying)
    }
}
