//
//  AudioPlayerServiceTests.swift
//  Still Moment
//

import AVFoundation
import Combine
import MediaPlayer
import XCTest
@testable import StillMoment

// MARK: - AudioPlayerServiceTests

// swiftlint:disable file_length type_body_length
final class AudioPlayerServiceTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCoordinator: MockAudioSessionCoordinator!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockNowPlayingProvider: MockNowPlayingInfoProvider!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        self.mockCoordinator = MockAudioSessionCoordinator()
        self.mockNowPlayingProvider = MockNowPlayingInfoProvider()
        self.sut = AudioPlayerService(
            coordinator: self.mockCoordinator,
            nowPlayingProvider: self.mockNowPlayingProvider
        )
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        self.sut.cleanup()
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
        self.mockNowPlayingProvider = nil
        self.mockCoordinator = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertEqual(self.sut.state.value, .idle)
        XCTAssertEqual(self.sut.currentTime.value, 0)
        XCTAssertEqual(self.sut.duration.value, 0)
    }

    func testInitializationWithDefaultCoordinator() {
        // When
        let service = AudioPlayerService()

        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.state.value, .idle)

        service.cleanup()
    }

    // MARK: - Load Tests

    @MainActor
    func testLoadAudioFile() async {
        // Given
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()

        // When
        do {
            try await self.sut.load(url: url, meditation: meditation)

            // Then
            // State should be paused after loading
            XCTAssertEqual(self.sut.state.value, .paused)
            XCTAssertGreaterThan(self.sut.duration.value, 0)
        } catch {
            XCTFail("Load should not throw: \(error)")
        }
    }

    @MainActor
    func testLoadInvalidAudioFile() async {
        // Given
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.mp3")
        let meditation = self.createTestMeditation()

        // When/Then
        do {
            try await self.sut.load(url: invalidURL, meditation: meditation)
            XCTFail("Should throw for invalid file")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is AudioPlayerError)
        }
    }

    // MARK: - Play/Pause/Stop Tests

    func testPlayWithoutLoading() {
        // When/Then
        XCTAssertThrowsError(try self.sut.play()) { error in
            guard let audioError = error as? AudioPlayerError else {
                XCTFail("Expected AudioPlayerError")
                return
            }
            if case .playbackFailed = audioError {
                // Expected
            } else {
                XCTFail("Expected playbackFailed error")
            }
        }
    }

    @MainActor
    func testPlayAfterLoading() async {
        // Given
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        // When
        XCTAssertNoThrow(try self.sut.play())

        // Then
        XCTAssertEqual(self.sut.state.value, .playing)

        // Verify coordinator was called
        let expectation = self.expectation(description: "Coordinator called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockCoordinator.requestedSources.contains(.guidedMeditation))
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func testPause() async {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        // When
        self.sut.pause()

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    @MainActor
    func testStop() async {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        // When
        self.sut.stop()

        // Then
        XCTAssertEqual(self.sut.state.value, .idle)
        XCTAssertEqual(self.sut.currentTime.value, 0)

        // Verify coordinator was called to release
        let expectation = self.expectation(description: "Coordinator released")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockCoordinator.releasedSources.contains(.guidedMeditation))
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func testStopClearsNowPlayingInfo() async {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        // Verify Now Playing info is set
        XCTAssertNotNil(self.mockNowPlayingProvider.nowPlayingInfo)

        // When
        self.sut.stop()

        // Then - Now Playing info should be cleared
        XCTAssertNil(
            self.mockNowPlayingProvider.nowPlayingInfo,
            "Now Playing info should be cleared when meditation is stopped"
        )
    }

    // MARK: - Seek Tests

    func testSeekWithoutLoading() {
        // When/Then
        XCTAssertThrowsError(try self.sut.seek(to: 10.0)) { error in
            guard let audioError = error as? AudioPlayerError else {
                XCTFail("Expected AudioPlayerError")
                return
            }
            if case .playbackFailed = audioError {
                // Expected
            } else {
                XCTFail("Expected playbackFailed error")
            }
        }
    }

    @MainActor
    func testSeekAfterLoading() async {
        // Given
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        // When
        XCTAssertNoThrow(try self.sut.seek(to: 1.0))

        // Then - Seek completion is asynchronous
        let expectation = self.expectation(description: "Seek completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Remote Command Center Tests

    func testSetupRemoteCommandCenter() {
        // When
        self.sut.setupRemoteCommandCenter()

        // Then
        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertTrue(commandCenter.playCommand.isEnabled)
        XCTAssertTrue(commandCenter.pauseCommand.isEnabled)
        XCTAssertTrue(commandCenter.togglePlayPauseCommand.isEnabled)
        XCTAssertTrue(commandCenter.changePlaybackPositionCommand.isEnabled)
        XCTAssertTrue(commandCenter.skipForwardCommand.isEnabled)
        XCTAssertTrue(commandCenter.skipBackwardCommand.isEnabled)
    }

    @MainActor
    func testStopDisablesRemoteCommandCenter() async {
        // Given - Load, play, and setup remote commands
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        self.sut.setupRemoteCommandCenter()
        try? self.sut.play()

        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertTrue(commandCenter.playCommand.isEnabled, "Commands should be enabled after setup")

        // When
        self.sut.stop()

        // Then - Remote commands should be disabled
        XCTAssertFalse(
            commandCenter.playCommand.isEnabled,
            "Play command should be disabled after stop"
        )
        XCTAssertFalse(
            commandCenter.pauseCommand.isEnabled,
            "Pause command should be disabled after stop"
        )
        XCTAssertFalse(
            commandCenter.togglePlayPauseCommand.isEnabled,
            "Toggle play/pause command should be disabled after stop"
        )
        XCTAssertFalse(
            commandCenter.changePlaybackPositionCommand.isEnabled,
            "Position command should be disabled after stop"
        )
        XCTAssertFalse(
            commandCenter.skipForwardCommand.isEnabled,
            "Skip forward should be disabled after stop"
        )
        XCTAssertFalse(
            commandCenter.skipBackwardCommand.isEnabled,
            "Skip backward should be disabled after stop"
        )
    }

    @MainActor
    func testCleanupDisablesRemoteCommandCenter() async {
        // Given - Load and setup remote commands
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        self.sut.setupRemoteCommandCenter()

        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertTrue(commandCenter.playCommand.isEnabled, "Commands should be enabled after setup")

        // When
        self.sut.cleanup()

        // Then - Remote commands should be disabled
        XCTAssertFalse(
            commandCenter.playCommand.isEnabled,
            "Play command should be disabled after cleanup"
        )
        XCTAssertFalse(
            commandCenter.pauseCommand.isEnabled,
            "Pause command should be disabled after cleanup"
        )
        XCTAssertFalse(
            commandCenter.togglePlayPauseCommand.isEnabled,
            "Toggle play/pause command should be disabled after cleanup"
        )
        XCTAssertFalse(
            commandCenter.changePlaybackPositionCommand.isEnabled,
            "Position command should be disabled after cleanup"
        )
        XCTAssertFalse(
            commandCenter.skipForwardCommand.isEnabled,
            "Skip forward should be disabled after cleanup"
        )
        XCTAssertFalse(
            commandCenter.skipBackwardCommand.isEnabled,
            "Skip backward should be disabled after cleanup"
        )
    }

    // MARK: - Cleanup Tests

    func testCleanup() {
        // Given - Some state
        self.sut.currentTime.send(10.0)
        self.sut.duration.send(100.0)

        // When
        self.sut.cleanup()

        // Then
        XCTAssertEqual(self.sut.currentTime.value, 0)
        XCTAssertEqual(self.sut.duration.value, 0)
    }

    @MainActor
    func testCleanupReleasesAudioSession() async {
        // Given - Load audio
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        // When
        self.sut.cleanup()

        // Then - Verify coordinator was called to release
        let expectation = self.expectation(description: "Coordinator released")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockCoordinator.releasedSources.contains(.guidedMeditation))
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - State Publisher Tests

    func testStatePublisher() {
        // Given
        let expectation = self.expectation(description: "State updates")
        var receivedStates: [PlaybackState] = []

        self.sut.state
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        // When
        self.sut.state.send(.loading)

        // Then
        self.wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
        XCTAssertEqual(receivedStates[0], .idle)
        XCTAssertEqual(receivedStates[1], .loading)
    }

    // MARK: - Coordinator Observer Tests

    @MainActor
    func testCoordinatorCallbackPausesOnConflict() async throws {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()
        XCTAssertEqual(self.sut.state.value, .playing)

        // When - Another source requests audio session (callback is called synchronously)
        _ = try? self.mockCoordinator.requestAudioSession(for: .timer)

        // Then - Player should be paused immediately (synchronous callback, no waiting needed)
        XCTAssertEqual(
            self.sut.state.value,
            .paused,
            "Player should pause when another audio source becomes active"
        )
    }

    @MainActor
    func testConflictHandlerClearsNowPlayingInfo() async throws {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()
        XCTAssertEqual(self.sut.state.value, .playing)

        // Verify Now Playing info is set
        XCTAssertNotNil(self.mockNowPlayingProvider.nowPlayingInfo)

        // When - Another source (timer) requests audio session
        let granted = try? self.mockCoordinator.requestAudioSession(for: .timer)
        XCTAssertTrue(granted == true, "Timer should successfully request audio session")

        // Then - Now Playing info should be cleared
        XCTAssertNil(
            self.mockNowPlayingProvider.nowPlayingInfo,
            "Now Playing info should be cleared when another audio source takes over"
        )
    }

    @MainActor
    func testConflictHandlerReleasesAudioSession() async throws {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        // Reset release tracking
        self.mockCoordinator.releasedSources.removeAll()

        // When - Another source requests session (triggers conflict handler)
        _ = try? self.mockCoordinator.requestAudioSession(for: .timer)

        // Then - Audio session should be released
        XCTAssertTrue(
            self.mockCoordinator.releasedSources.contains(.guidedMeditation),
            "Conflict handler should release audio session when another source takes over"
        )
    }

    @MainActor
    func testPlaySetsNowPlayingInfoAfterSessionActivation() async {
        // Given - Load meditation
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        // Verify Now Playing info is NOT set after load
        XCTAssertNil(
            self.mockNowPlayingProvider.nowPlayingInfo,
            "Now Playing info should NOT be set during load (session not active yet)"
        )

        // When - Play starts
        try? self.sut.play()

        // Then - Now Playing info should be set
        let nowPlaying = self.mockNowPlayingProvider.nowPlayingInfo
        XCTAssertNotNil(nowPlaying, "Now Playing info should be set during play (session is active)")
        XCTAssertEqual(nowPlaying?[MPMediaItemPropertyTitle] as? String, meditation.effectiveName)
        XCTAssertEqual(nowPlaying?[MPMediaItemPropertyArtist] as? String, meditation.effectiveTeacher)
    }

    @MainActor
    func testPlaySetsArtworkInNowPlayingInfo() async {
        // Given - Load meditation
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        // When - Play starts
        try? self.sut.play()

        // Then - Artwork should be set in Now Playing info (if LockScreenArtwork is available)
        let nowPlaying = self.mockNowPlayingProvider.nowPlayingInfo
        XCTAssertNotNil(nowPlaying, "Now Playing info should be set")

        // The artwork will only be set if UIImage(named: "LockScreenArtwork") returns a valid image
        // In the test bundle, this should work since we're running in the app context
        let artwork = nowPlaying?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork
        XCTAssertNotNil(
            artwork,
            "Artwork should be set in Now Playing info for lock screen display"
        )
    }

    @MainActor
    func testPlayConfiguresRemoteCommandCenterOnce() async {
        // Given - Load meditation
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertFalse(
            commandCenter.playCommand.isEnabled,
            "Commands should NOT be enabled after load"
        )

        // When - Play for first time
        try? self.sut.play()

        // Then - Commands should be enabled
        XCTAssertTrue(
            commandCenter.playCommand.isEnabled,
            "Commands should be enabled during first play"
        )

        // When - Pause and play again
        self.sut.pause()
        try? self.sut.play()

        // Then - Commands should still be enabled (not reconfigured)
        XCTAssertTrue(
            commandCenter.playCommand.isEnabled,
            "Commands should remain enabled on subsequent play calls"
        )
    }

    @MainActor
    func testRapidPlayCallsDoNotDuplicateSetup() async {
        // Given - Load meditation
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        let commandCenter = MPRemoteCommandCenter.shared()

        // When - Call play() multiple times rapidly
        try? self.sut.play()
        let firstSetupEnabled = commandCenter.playCommand.isEnabled

        try? self.sut.play()
        try? self.sut.play()

        // Then - Commands should still be enabled (not broken by duplicate setup)
        XCTAssertTrue(firstSetupEnabled, "Commands should be enabled after first play")
        XCTAssertTrue(
            commandCenter.playCommand.isEnabled,
            "Commands should remain enabled after rapid play() calls"
        )

        // And - Now Playing info should be set (not cleared by duplicate setup)
        XCTAssertNotNil(
            self.mockNowPlayingProvider.nowPlayingInfo,
            "Now Playing info should be set and not cleared by rapid play() calls"
        )
    }

    @MainActor
    func testPlayFailsWhenSessionActivationFails() async {
        // Given - Load meditation and configure coordinator to fail
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)

        self.mockCoordinator.shouldFailActivation = true

        // When - Attempt to play
        var thrownError: Error?
        do {
            try self.sut.play()
            XCTFail("play() should throw when session activation fails")
        } catch {
            thrownError = error
        }

        // Then - Should throw AudioSessionCoordinatorError
        XCTAssertNotNil(thrownError, "play() should throw an error")
        XCTAssertTrue(
            thrownError is AudioSessionCoordinatorError,
            "Should throw AudioSessionCoordinatorError when session activation fails"
        )

        // And - Remote commands should NOT be configured
        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertFalse(
            commandCenter.playCommand.isEnabled,
            "Remote commands should NOT be configured when session activation fails"
        )

        // And - Now Playing info should NOT be set
        XCTAssertNil(
            self.mockNowPlayingProvider.nowPlayingInfo,
            "Now Playing info should NOT be set when session activation fails"
        )
    }

    // Note: handlePlaybackFinished() uses the same cleanup logic as stop().
    // Direct testing is not possible (private method, notification requires specific playerItem).
    // Coverage is provided indirectly by: testStopClearsNowPlayingInfo, testStopDisablesRemoteCommandCenter

    @MainActor
    func testCleanupResetsRemoteCommandsConfiguredFlag() async {
        // Given - Load and play
        guard let url = self.createTestAudioURL() else {
            XCTFail("Test audio file not found")
            return
        }
        let meditation = self.createTestMeditation()
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        let commandCenter = MPRemoteCommandCenter.shared()
        XCTAssertTrue(commandCenter.playCommand.isEnabled)

        // When - Cleanup
        self.sut.cleanup()

        // Then - Commands should be disabled
        XCTAssertFalse(commandCenter.playCommand.isEnabled)

        // When - Load and play again (tests flag reset)
        try? await self.sut.load(url: url, meditation: meditation)
        try? self.sut.play()

        // Then - Commands should be enabled again
        XCTAssertTrue(
            commandCenter.playCommand.isEnabled,
            "Commands should be configured again after cleanup (flag was reset)"
        )
    }

    // MARK: - Silent Background Audio Tests

    func testStartSilentBackgroundAudio_SoundNotConfigured_ThrowsFileNotAccessible() {
        // Given
        let mockRepository = MockBackgroundSoundRepository()
        mockRepository.soundsToReturn = [] // No "silent" sound configured

        let service = AudioPlayerService(
            coordinator: self.mockCoordinator,
            nowPlayingProvider: self.mockNowPlayingProvider,
            soundRepository: mockRepository
        )

        // When/Then
        XCTAssertThrowsError(try service.startSilentBackgroundAudio()) { error in
            guard let audioError = error as? AudioPlayerError else {
                XCTFail("Expected AudioPlayerError, got \(error)")
                return
            }
            if case .fileNotAccessible = audioError {
                // Success - expected error case
            } else {
                XCTFail("Expected .fileNotAccessible, got \(audioError)")
            }
        }

        service.cleanup()
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createTestMeditation() -> GuidedMeditation {
        GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600, // 10 minutes
            teacher: "Test Teacher",
            name: "Test Meditation"
        )
    }

    private func createTestAudioURL() -> URL? {
        // Use silence.mp3 from BackgroundAudio - it's short and ideal for testing
        Bundle.main.url(
            forResource: "silence",
            withExtension: "mp3",
            subdirectory: "BackgroundAudio"
        )
    }
}
