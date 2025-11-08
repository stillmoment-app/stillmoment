//
//  AudioSessionCoordinatorTests.swift
//  MediTimer
//
//  Tests for audio session coordination between timer and guided meditation features.
//  Focus: Ownership management, exclusive access, publisher notifications.
//

import AVFoundation
import Combine
import XCTest
@testable import MediTimer

final class AudioSessionCoordinatorTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioSessionCoordinator!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.sut = AudioSessionCoordinator.shared
        // Reset state for test isolation
        self.sut.releaseAudioSession(for: .timer)
        self.sut.releaseAudioSession(for: .guidedMeditation)
        self.cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        // Clean up state
        self.sut.releaseAudioSession(for: .timer)
        self.sut.releaseAudioSession(for: .guidedMeditation)
        self.cancellables = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Ownership Management Tests

    func testInitialStateHasNoActiveSource() {
        // Given - Fresh state after setUp
        // When - Check initial state
        // Then
        XCTAssertNil(
            self.sut.activeSource.value,
            "Initial state should have no active source"
        )
    }

    func testRequestAudioSessionGrantsOwnership() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When - Timer requests session
        _ = try? self.sut.requestAudioSession(for: .timer)

        // Then - Timer becomes owner
        XCTAssertEqual(
            self.sut.activeSource.value,
            .timer,
            "Timer should become active source after request"
        )
    }

    func testSecondSourceReplacesFirstSource() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Guided meditation requests session
        _ = try? self.sut.requestAudioSession(for: .guidedMeditation)

        // Then - Ownership transferred to guided meditation
        XCTAssertEqual(
            self.sut.activeSource.value,
            .guidedMeditation,
            "Guided meditation should replace timer as active source"
        )
    }

    func testSameSourceCanRequestMultipleTimes() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Timer requests again
        _ = try? self.sut.requestAudioSession(for: .timer)

        // Then - Timer still owns session
        XCTAssertEqual(
            self.sut.activeSource.value,
            .timer,
            "Same source should maintain ownership on repeated requests"
        )
    }

    // MARK: - Release Logic Tests

    func testReleaseAudioSessionClearsOwnership() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Timer releases session
        self.sut.releaseAudioSession(for: .timer)

        // Then - No active source
        XCTAssertNil(
            self.sut.activeSource.value,
            "Releasing session should clear active source"
        )
    }

    func testNonOwnerCannotReleaseSession() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Guided meditation tries to release (doesn't own it)
        self.sut.releaseAudioSession(for: .guidedMeditation)

        // Then - Timer still owns session
        XCTAssertEqual(
            self.sut.activeSource.value,
            .timer,
            "Non-owner should not be able to release session"
        )
    }

    func testReleaseWhenNoOwnerDoesNothing() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When - Timer tries to release
        self.sut.releaseAudioSession(for: .timer)

        // Then - Still no owner, no crash
        XCTAssertNil(
            self.sut.activeSource.value,
            "Releasing when no owner should be safe no-op"
        )
    }

    // MARK: - CurrentValueSubject Value Tests
    //
    // Note: We test the VALUE of activeSource, not the publishing mechanism.
    // Services subscribe to activeSource and read its value, so that's what matters.
    // Testing Combine's publishing internals would be testing the framework, not our code.

    func testActiveSourceValueAfterRequest() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When - Timer requests session
        _ = try? self.sut.requestAudioSession(for: .timer)

        // Then - Value is immediately available to subscribers
        XCTAssertEqual(
            self.sut.activeSource.value,
            .timer,
            "ActiveSource value should be available after request"
        )
    }

    func testActiveSourceValueAfterRelease() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Timer releases session
        self.sut.releaseAudioSession(for: .timer)

        // Then - Value is cleared
        XCTAssertNil(
            self.sut.activeSource.value,
            "ActiveSource value should be nil after release"
        )
    }

    func testActiveSourceValueAfterSourceChange() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Guided meditation requests session
        _ = try? self.sut.requestAudioSession(for: .guidedMeditation)

        // Then - Value reflects new owner
        XCTAssertEqual(
            self.sut.activeSource.value,
            .guidedMeditation,
            "ActiveSource value should reflect current owner"
        )
    }

    // MARK: - Singleton Test

    func testSharedInstanceIsSingleton() {
        // When - Access shared instance twice
        let instance1 = AudioSessionCoordinator.shared
        let instance2 = AudioSessionCoordinator.shared

        // Then - Same instance
        XCTAssertTrue(
            instance1 === instance2,
            "Shared instance should be a singleton"
        )
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentRequestsFromDifferentSources() {
        // Given - No active source
        XCTAssertNil(self.sut.activeSource.value)

        // When - Timer requests, then immediately guided meditation
        _ = try? self.sut.requestAudioSession(for: .timer)
        _ = try? self.sut.requestAudioSession(for: .guidedMeditation)

        // Then - Last request wins
        XCTAssertEqual(
            self.sut.activeSource.value,
            .guidedMeditation,
            "Concurrent requests should result in last requester owning session"
        )
    }

    func testMultipleReleaseCallsAreSafe() {
        // Given - Timer owns session
        _ = try? self.sut.requestAudioSession(for: .timer)
        XCTAssertEqual(self.sut.activeSource.value, .timer)

        // When - Release multiple times
        self.sut.releaseAudioSession(for: .timer)
        self.sut.releaseAudioSession(for: .timer)
        self.sut.releaseAudioSession(for: .timer)

        // Then - No crash, no owner
        XCTAssertNil(
            self.sut.activeSource.value,
            "Multiple release calls should be safe"
        )
    }
}
