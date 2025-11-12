//
//  AudioPlayerServiceTests.swift
//  Still Moment
//

import AVFoundation
import Combine
import MediaPlayer
import XCTest
@testable import StillMoment

// MARK: - Mock Audio Session Coordinator

final class MockAudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    // MARK: Internal

    let activeSource = CurrentValueSubject<AudioSource?, Never>(nil)
    var requestedSources: [AudioSource] = []
    var releasedSources: [AudioSource] = []
    var activationCount = 0
    var deactivationCount = 0
    var shouldFailActivation = false

    func registerConflictHandler(for source: AudioSource, handler: @escaping () -> Void) {
        self.conflictHandlers[source] = handler
    }

    func requestAudioSession(for source: AudioSource) throws -> Bool {
        self.requestedSources.append(source)

        if self.shouldFailActivation {
            throw AudioSessionCoordinatorError.sessionActivationFailed
        }

        // If another source is active, call its conflict handler
        if let currentSource = activeSource.value, currentSource != source {
            self.conflictHandlers[currentSource]?()
        }

        self.activeSource.send(source)
        return true
    }

    func releaseAudioSession(for source: AudioSource) {
        self.releasedSources.append(source)
        if self.activeSource.value == source {
            self.activeSource.send(nil)
        }
    }

    func activateAudioSession() throws {
        self.activationCount += 1
        if self.shouldFailActivation {
            throw AudioSessionCoordinatorError.sessionActivationFailed
        }
    }

    func deactivateAudioSession() {
        self.deactivationCount += 1
    }

    // MARK: Private

    private var conflictHandlers: [AudioSource: () -> Void] = [:]
}

// MARK: - AudioPlayerServiceTests

final class AudioPlayerServiceTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCoordinator: MockAudioSessionCoordinator!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        self.mockCoordinator = MockAudioSessionCoordinator()
        self.sut = AudioPlayerService(coordinator: self.mockCoordinator)
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        self.sut.cleanup()
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
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
        XCTAssertNotNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)

        // When
        self.sut.stop()

        // Then - Now Playing info should be cleared
        XCTAssertNil(
            MPNowPlayingInfoCenter.default().nowPlayingInfo,
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
        XCTAssertTrue(commandCenter.changePlaybackPositionCommand.isEnabled)
        XCTAssertTrue(commandCenter.skipForwardCommand.isEnabled)
        XCTAssertTrue(commandCenter.skipBackwardCommand.isEnabled)
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
        XCTAssertNotNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)

        // When - Another source (timer) requests audio session
        let granted = try? self.mockCoordinator.requestAudioSession(for: .timer)
        XCTAssertTrue(granted == true, "Timer should successfully request audio session")

        // Then - Now Playing info should be cleared
        XCTAssertNil(
            MPNowPlayingInfoCenter.default().nowPlayingInfo,
            "Now Playing info should be cleared when another audio source takes over"
        )
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
        // Use the completion.mp3 file that exists in the bundle for testing
        Bundle.main.url(forResource: "completion", withExtension: "mp3")
    }
}
