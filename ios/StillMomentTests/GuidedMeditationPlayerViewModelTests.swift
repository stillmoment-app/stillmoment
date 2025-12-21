//
//  GuidedMeditationPlayerViewModelTests.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

// MARK: - GuidedMeditationPlayerViewModelTests

@MainActor
final class GuidedMeditationPlayerViewModelTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.cancellables = Set<AnyCancellable>()

        // Create temporary file for tests
        self.tempFileURL = self.createTemporaryAudioFile()

        let meditation = self.createTestMeditation(fileURL: self.tempFileURL)
        self.sut = GuidedMeditationPlayerViewModel(
            meditation: meditation,
            playerService: self.mockPlayerService
        )
    }

    override func tearDown() {
        self.sut.cleanup()
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
        self.mockPlayerService = nil
        // Clean up temp file
        if let tempFileURL {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        self.tempFileURL = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertEqual(self.sut.playbackState, .idle)
        XCTAssertEqual(self.sut.currentTime, 0)
        XCTAssertEqual(self.sut.duration, 0)
        XCTAssertNil(self.sut.errorMessage)
        // Remote commands are NOT configured on init anymore (moved to play())
        XCTAssertFalse(self.mockPlayerService.setupRemoteCommandCenterCalled)
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
    }

    func testLoadAudioWithMissingFile() async {
        // Given - Create meditation pointing to non-existent file
        let missingMeditation = self.createTestMeditation(fileURL: URL(fileURLWithPath: "/nonexistent/file.mp3"))
        self.sut = GuidedMeditationPlayerViewModel(
            meditation: missingMeditation,
            playerService: self.mockPlayerService
        )

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertNil(self.mockPlayerService.loadedURL)
    }

    func testLoadAudioWithNoLocalFilePath() async {
        // Given - Meditation without local file path (legacy bookmark-only)
        let legacyMeditation = GuidedMeditation(
            fileBookmark: Data("fake-bookmark".utf8),
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation"
        )
        self.sut = GuidedMeditationPlayerViewModel(
            meditation: legacyMeditation,
            playerService: self.mockPlayerService
        )

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertNil(self.mockPlayerService.loadedURL)
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

    // MARK: Private

    // MARK: - Helper Methods

    private func createTestMeditation(fileURL: URL) -> GuidedMeditation {
        // Extract the path relative to Application Support/Meditations/
        // For tests, we use a custom path but need to make fileURL work
        let meditationId = UUID()
        let localFileName = "\(meditationId.uuidString).mp3"

        // Create the Meditations directory and symlink the temp file
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let meditationsDir = appSupport.appendingPathComponent("Meditations")
            try? fileManager.createDirectory(at: meditationsDir, withIntermediateDirectories: true)
            let targetURL = meditationsDir.appendingPathComponent(localFileName)
            try? fileManager.removeItem(at: targetURL)
            try? fileManager.copyItem(at: fileURL, to: targetURL)
        }

        return GuidedMeditation(
            id: meditationId,
            localFilePath: localFileName,
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation"
        )
    }

    private func createTemporaryAudioFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_audio_\(UUID().uuidString).mp3")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        return fileURL
    }
}

// MARK: - State, Cleanup & Bindings Tests

@MainActor
extension GuidedMeditationPlayerViewModelTests {
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

    func testCleanup() {
        // When
        self.sut.cleanup()

        // Then
        XCTAssertTrue(self.mockPlayerService.cleanupCalled)
    }

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
}
