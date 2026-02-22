//
//  AudioServiceIntegrationTests.swift
//  Still Moment
//
//  Integration tests for AudioService (full audio flows with async waits)
//

import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceIntegrationTests: XCTestCase {
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

        // When - Simulate full meditation cycle with always-on keep-alive
        try service.activateTimerSession()
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
        try service.playIntervalGong(soundId: GongSound.defaultSoundId, volume: 1.0)

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

        // Then - Clean deactivation
        service.deactivateTimerSession()
    }
}
