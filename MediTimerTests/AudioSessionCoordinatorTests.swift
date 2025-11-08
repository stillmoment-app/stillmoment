//
//  AudioSessionCoordinatorTests.swift
//  MediTimer
//

import AVFoundation
import Combine
import XCTest
@testable import MediTimer

@MainActor
final class AudioSessionCoordinatorTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioSessionCoordinator!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.sut = AudioSessionCoordinator.shared
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        self.sut.releaseAudioSession(for: .timer)
        self.sut.releaseAudioSession(for: .guidedMeditation)
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Audio Session Request Tests

    func testRequestAudioSessionForTimer() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When
        var granted = false
        XCTAssertNoThrow(granted = try self.sut.requestAudioSession(for: .timer))

        // Then
        XCTAssertTrue(granted)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // Verify audio session is active
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)
    }

    func testRequestAudioSessionForGuidedMeditation() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When
        var granted = false
        XCTAssertNoThrow(granted = try self.sut.requestAudioSession(for: .guidedMeditation))

        // Then
        XCTAssertTrue(granted)
        XCTAssertEqual(self.sut.activeSource.value, .guidedMeditation)
    }

    func testRequestAudioSessionFromSameSourceTwice() {
        // Given - Timer already owns the session
        try? self.sut.requestAudioSession(for: .timer)

        // When - Request again
        var granted = false
        XCTAssertNoThrow(granted = try self.sut.requestAudioSession(for: .timer))

        // Then - Should still be granted
        XCTAssertTrue(granted)
        XCTAssertEqual(self.sut.activeSource.value, .timer)
    }

    func testRequestAudioSessionFromDifferentSource() {
        // Given - Timer owns the session
        try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Guided meditation requests
        var granted = false
        XCTAssertNoThrow(granted = try self.sut.requestAudioSession(for: .guidedMeditation))

        // Then - Should be granted and ownership transferred
        XCTAssertTrue(granted)
        XCTAssertEqual(self.sut.activeSource.value, .guidedMeditation)
    }

    // MARK: - Audio Session Release Tests

    func testReleaseAudioSession() {
        // Given - Timer owns the session
        try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When
        self.sut.releaseAudioSession(for: .timer)

        // Then
        XCTAssertNil(self.sut.activeSource.value)
    }

    func testReleaseAudioSessionFromNonOwner() {
        // Given - Timer owns the session
        try? self.sut.requestAudioSession(for: .timer)

        // When - Guided meditation tries to release (doesn't own it)
        self.sut.releaseAudioSession(for: .guidedMeditation)

        // Then - Timer should still own the session
        XCTAssertEqual(self.sut.activeSource.value, .timer)
    }

    func testReleaseAudioSessionWhenNoActiveSource() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When
        self.sut.releaseAudioSession(for: .timer)

        // Then - Should not crash
        XCTAssertNil(self.sut.activeSource.value)
    }

    // MARK: - Combine Publisher Tests

    func testActiveSourcePublisher() {
        // Given
        let expectation = self.expectation(description: "Active source updates")
        expectation.expectedFulfillmentCount = 2 // Initial nil + timer

        var receivedSources: [AudioSource?] = []

        self.sut.activeSource
            .sink { source in
                receivedSources.append(source)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        try? self.sut.requestAudioSession(for: .timer)

        // Then
        self.wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSources.count, 2)
        XCTAssertNil(receivedSources[0]) // Initial value
        XCTAssertEqual(receivedSources[1], .timer)
    }

    func testActiveSourcePublisherOnSourceChange() {
        // Given
        let expectation = self.expectation(description: "Source changes")
        expectation.expectedFulfillmentCount = 3 // Initial nil + timer + guidedMeditation

        var receivedSources: [AudioSource?] = []

        self.sut.activeSource
            .sink { source in
                receivedSources.append(source)
                expectation.fulfill()
            }
            .store(in: &self.cancellables)

        // When
        try? self.sut.requestAudioSession(for: .timer)
        try? self.sut.requestAudioSession(for: .guidedMeditation)

        // Then
        self.wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSources.count, 3)
        XCTAssertNil(receivedSources[0])
        XCTAssertEqual(receivedSources[1], .timer)
        XCTAssertEqual(receivedSources[2], .guidedMeditation)
    }

    // MARK: - Session Activation/Deactivation Tests

    func testActivateAudioSession() {
        // When
        XCTAssertNoThrow(try self.sut.activateAudioSession())

        // Then
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)
    }

    func testActivateAudioSessionMultipleTimes() {
        // Given - Activate once
        try? self.sut.activateAudioSession()

        // When - Activate again
        XCTAssertNoThrow(try self.sut.activateAudioSession())

        // Then - Should still be active
        let audioSession = AVAudioSession.sharedInstance()
        XCTAssertEqual(audioSession.category, .playback)
    }

    func testDeactivateAudioSession() {
        // Given - Session is active
        try? self.sut.activateAudioSession()

        // When
        self.sut.deactivateAudioSession()

        // Then - Should not throw (deactivation is non-critical)
        // Note: Can't reliably test session deactivation state due to system-level management
        XCTAssertNoThrow(self.sut.deactivateAudioSession())
    }

    // MARK: - Singleton Tests

    func testSingletonInstance() {
        // When
        let instance1 = AudioSessionCoordinator.shared
        let instance2 = AudioSessionCoordinator.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "Should be the same instance")
    }
}
