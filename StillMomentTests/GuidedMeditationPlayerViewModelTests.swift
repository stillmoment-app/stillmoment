//
//  GuidedMeditationPlayerViewModelTests.swift
//  Still Moment
//
// swiftlint:disable file_length type_body_length

import Combine
import XCTest
@testable import StillMoment

// MARK: - Mock Audio Player Service

final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    var state = CurrentValueSubject<PlaybackState, Never>(.idle)
    var currentTime = CurrentValueSubject<TimeInterval, Never>(0)
    var duration = CurrentValueSubject<TimeInterval, Never>(0)

    var loadedMeditation: GuidedMeditation?
    var loadedURL: URL?
    var loadShouldThrow = false
    var playCalled = false
    var pauseCalled = false
    var stopCalled = false
    var seekTime: TimeInterval?
    var cleanupCalled = false
    var setupRemoteCommandCenterCalled = false

    func load(url: URL, meditation: GuidedMeditation) async throws {
        if self.loadShouldThrow {
            throw AudioPlayerError.playbackFailed(reason: "Mock error")
        }
        self.loadedURL = url
        self.loadedMeditation = meditation
        self.state.send(.paused)
        self.duration.send(600) // 10 minutes
    }

    func play() throws {
        self.playCalled = true
        self.state.send(.playing)
    }

    func pause() {
        self.pauseCalled = true
        self.state.send(.paused)
    }

    func stop() {
        self.stopCalled = true
        self.state.send(.idle)
        self.currentTime.send(0)
    }

    func seek(to time: TimeInterval) throws {
        self.seekTime = time
        self.currentTime.send(time)
    }

    func configureAudioSession() throws {
        // Mock implementation
    }

    func setupRemoteCommandCenter() {
        self.setupRemoteCommandCenterCalled = true
    }

    func cleanup() {
        self.cleanupCalled = true
        self.state.send(.idle)
        self.currentTime.send(0)
        self.duration.send(0)
    }
}

// MARK: - Mock Guided Meditation Service

final class MockGuidedMeditationService: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation] = []
    var resolvedURL: URL?
    var startAccessingCalled = false
    var stopAccessingCalled = false
    var resolveShouldThrow = false
    var startAccessingShouldFail = false

    func loadMeditations() throws -> [GuidedMeditation] {
        self.meditations
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        self.meditations = meditations
    }

    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        let meditation = GuidedMeditation(
            fileBookmark: Data(),
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown",
            name: metadata.title ?? "Untitled"
        )
        self.meditations.append(meditation)
        return meditation
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {
        if let index = self.meditations.firstIndex(where: { $0.id == meditation.id }) {
            self.meditations[index] = meditation
        }
    }

    func deleteMeditation(id: UUID) throws {
        self.meditations.removeAll { $0.id == id }
    }

    func resolveBookmark(_ bookmark: Data) throws -> URL {
        if self.resolveShouldThrow {
            throw GuidedMeditationError.bookmarkResolutionFailed
        }
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        self.resolvedURL = url
        return url
    }

    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        self.startAccessingCalled = true
        return !self.startAccessingShouldFail
    }

    func stopAccessingSecurityScopedResource(_ url: URL) {
        self.stopAccessingCalled = true
    }
}

// MARK: - GuidedMeditationPlayerViewModelTests

@MainActor
final class GuidedMeditationPlayerViewModelTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.mockMeditationService = MockGuidedMeditationService()
        self.cancellables = Set<AnyCancellable>()

        let meditation = self.createTestMeditation()
        self.sut = GuidedMeditationPlayerViewModel(
            meditation: meditation,
            playerService: self.mockPlayerService,
            meditationService: self.mockMeditationService
        )
    }

    override func tearDown() {
        self.sut.cleanup()
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
        self.mockMeditationService = nil
        self.mockPlayerService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertEqual(self.sut.playbackState, .idle)
        XCTAssertEqual(self.sut.currentTime, 0)
        XCTAssertEqual(self.sut.duration, 0)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertTrue(self.mockPlayerService.setupRemoteCommandCenterCalled)
    }

    // MARK: - Load Audio Tests

    func testLoadAudioSuccess() async {
        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.mockPlayerService.loadedURL)
        XCTAssertNotNil(self.mockPlayerService.loadedMeditation)
        XCTAssertEqual(self.sut.playbackState, .paused)
        XCTAssertEqual(self.sut.duration, 600)
        XCTAssertNil(self.sut.errorMessage)
        XCTAssertTrue(self.mockMeditationService.startAccessingCalled)
        XCTAssertTrue(self.mockMeditationService.stopAccessingCalled)
    }

    func testLoadAudioBookmarkResolutionFails() async {
        // Given
        self.mockMeditationService.resolveShouldThrow = true

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertNil(self.mockPlayerService.loadedURL)
    }

    func testLoadAudioAccessDenied() async {
        // Given
        self.mockMeditationService.startAccessingShouldFail = true

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertTrue(self.mockMeditationService.startAccessingCalled)
    }

    func testLoadAudioPlayerServiceFails() async {
        // Given
        self.mockPlayerService.loadShouldThrow = true

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
    }

    // MARK: - Toggle Play/Pause Tests

    func testTogglePlayPauseFromPaused() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "State updates to playing")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.paused)
        self.sut.playbackState = .paused

        // When
        self.sut.togglePlayPause()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(self.mockPlayerService.playCalled)
        XCTAssertEqual(self.sut.playbackState, .playing)
    }

    func testTogglePlayPauseFromPlaying() async {
        // Given
        await self.sut.loadAudio()

        let playingExpectation = self.expectation(description: "State updates to playing")
        let pausedExpectation = self.expectation(description: "State updates to paused")

        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    playingExpectation.fulfill()
                } else if state == .paused {
                    pausedExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        try? self.mockPlayerService.play()
        await fulfillment(of: [playingExpectation], timeout: 1.0)

        // When
        self.sut.togglePlayPause()

        // Then
        await fulfillment(of: [pausedExpectation], timeout: 1.0)
        XCTAssertTrue(self.mockPlayerService.pauseCalled)
        XCTAssertEqual(self.sut.playbackState, .paused)
    }

    func testTogglePlayPauseFromFinished() async {
        // Given
        await self.sut.loadAudio()

        let finishedExpectation = self.expectation(description: "State updates to finished")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finishedExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.finished)
        await fulfillment(of: [finishedExpectation], timeout: 1.0)

        // When
        self.sut.togglePlayPause()

        // Then
        XCTAssertNotNil(self.mockPlayerService.seekTime)
        XCTAssertEqual(self.mockPlayerService.seekTime, 0)
        XCTAssertTrue(self.mockPlayerService.playCalled)
    }

    // MARK: - Stop Tests

    func testStop() {
        // When
        self.sut.stop()

        // Then
        XCTAssertTrue(self.mockPlayerService.stopCalled)
    }

    // MARK: - Seek Tests

    func testSeek() {
        // When
        self.sut.seek(to: 30.0)

        // Then
        XCTAssertEqual(self.mockPlayerService.seekTime, 30.0)
    }

    func testSkipForward() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 10.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(10.0)
        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        self.sut.skipForward(by: 15)

        // Then
        XCTAssertEqual(self.mockPlayerService.seekTime, 25.0)
    }

    func testSkipForwardNearEnd() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 595.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(595.0)
        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        self.sut.skipForward(by: 15)

        // Then
        // Should cap at duration
        XCTAssertEqual(self.mockPlayerService.seekTime, 600.0)
    }

    func testSkipBackward() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 30.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(30.0)
        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        self.sut.skipBackward(by: 15)

        // Then
        XCTAssertEqual(self.mockPlayerService.seekTime, 15.0)
    }

    func testSkipBackwardNearStart() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 5.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(5.0)
        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        self.sut.skipBackward(by: 15)

        // Then
        // Should cap at 0
        XCTAssertEqual(self.mockPlayerService.seekTime, 0)
    }

    // MARK: - Computed Properties Tests

    func testFormattedCurrentTime() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst() // Skip initial 0
            .sink { time in
                if time == 125.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(125.0) // 2:05

        // Wait for binding to propagate
        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        let formatted = self.sut.formattedCurrentTime

        // Then
        XCTAssertEqual(formatted, "2:05")
    }

    func testFormattedCurrentTimeWithHours() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 3665.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(3665.0) // 1:01:05

        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        let formatted = self.sut.formattedCurrentTime

        // Then
        XCTAssertEqual(formatted, "1:01:05")
    }

    func testFormattedRemainingTime() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 100.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(100.0)

        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        let formatted = self.sut.formattedRemainingTime

        // Then
        // 600 - 100 = 500 seconds = 8:20
        XCTAssertEqual(formatted, "8:20")
    }

    func testProgress() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "Current time updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 300.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.currentTime.send(300.0) // Halfway

        await fulfillment(of: [expectation], timeout: 1.0)

        // When
        let progress = self.sut.progress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testProgressWithZeroDuration() {
        // Given - No audio loaded
        XCTAssertEqual(self.sut.duration, 0)

        // When
        let progress = self.sut.progress

        // Then
        XCTAssertEqual(progress, 0)
    }

    func testIsPlaying() async {
        // Given
        await self.sut.loadAudio()

        // When - Initially paused
        XCTAssertFalse(self.sut.isPlaying)

        // When - Playing
        let expectation = self.expectation(description: "State updates to playing")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.playing)
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(self.sut.isPlaying)
    }

    // MARK: - Cleanup Tests

    func testCleanup() {
        // When
        self.sut.cleanup()

        // Then
        XCTAssertTrue(self.mockPlayerService.cleanupCalled)
    }

    // MARK: - Bindings Tests

    func testStateBinding() async {
        // Given
        let expectation = self.expectation(description: "State binding")
        var receivedState: PlaybackState?

        self.sut.$playbackState
            .dropFirst() // Skip initial value
            .sink { state in
                receivedState = state
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        self.mockPlayerService.state.send(.playing)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState, .playing)
    }

    func testCurrentTimeBinding() async {
        // Given
        let expectation = self.expectation(description: "Current time binding")
        var receivedTime: TimeInterval?

        self.sut.$currentTime
            .dropFirst() // Skip initial value
            .sink { time in
                receivedTime = time
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        self.mockPlayerService.currentTime.send(42.0)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTime, 42.0)
    }

    func testDurationBinding() async {
        // Given
        let expectation = self.expectation(description: "Duration binding")
        var receivedDuration: TimeInterval?

        self.sut.$duration
            .dropFirst() // Skip initial value
            .sink { duration in
                receivedDuration = duration
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        self.mockPlayerService.duration.send(1200.0)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedDuration, 1200.0)
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createTestMeditation() -> GuidedMeditation {
        GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation"
        )
    }
}

// swiftlint:enable file_length type_body_length
