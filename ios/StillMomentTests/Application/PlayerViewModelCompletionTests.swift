//
//  PlayerViewModelCompletionTests.swift
//  Still Moment
//

import Combine
import SwiftUI
import XCTest
@testable import StillMoment

@MainActor
final class PlayerViewModelCompletionTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.mockMeditationService = MockGuidedMeditationService()
        self.cancellables = Set<AnyCancellable>()
        self.tempFileURL = GuidedMeditationTestHelpers.createTemporaryAudioFile()

        let meditation = GuidedMeditationTestHelpers.createTestMeditation(fileURL: self.tempFileURL)
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
        self.mockPlayerService = nil
        self.mockMeditationService = nil
        GuidedMeditationTestHelpers.cleanupTemporaryFile(self.tempFileURL)
        self.tempFileURL = nil
        GuidedMeditationTestHelpers.cleanupUserDefaults()
        super.tearDown()
    }

    // MARK: - Completion Event Tests

    func testCompletionEventSetWhenAudioFinishesNaturally() async {
        // Given
        let mockClock = MockClock()
        let meditation = GuidedMeditationTestHelpers.createTestMeditation(fileURL: self.tempFileURL)
        self.sut = GuidedMeditationPlayerViewModel(
            meditation: meditation,
            playerService: self.mockPlayerService,
            meditationService: self.mockMeditationService,
            clock: mockClock
        )
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "completionEvent is set")
        self.sut.$completionEvent
            .dropFirst()
            .sink { event in
                if event != nil { expectation.fulfill() }
            }
            .store(in: &self.cancellables)

        // When - audio reaches end naturally
        self.mockPlayerService.state.send(.finished)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(self.sut.completionEvent)
        XCTAssertEqual(self.sut.completionEvent?.meditationId, meditation.id)
        XCTAssertEqual(self.sut.completionEvent?.completedAt, mockClock.now())
    }

    func testCompletionEventNotSetOnManualStop() {
        // Given - state never reaches .finished
        self.sut.stop()

        // Then
        XCTAssertNil(self.sut.completionEvent)
    }

    func testCompletionEventNotSetOnAudioConflictStop() {
        // Given - stopForAudioSessionConflict sends .paused, not .finished
        self.mockPlayerService.state.send(.paused)

        // Then
        XCTAssertNil(self.sut.completionEvent)
    }

    func testCompletionEventNotSetTwiceOnMultipleFinishedEmissions() async {
        // Given
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "first completionEvent set")
        self.sut.$completionEvent
            .dropFirst()
            .first { $0 != nil }
            .sink { _ in expectation.fulfill() }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.finished)
        await fulfillment(of: [expectation], timeout: 1.0)

        let firstEvent = self.sut.completionEvent

        // When - duplicate .finished emission
        self.mockPlayerService.state.send(.finished)

        // Then - event unchanged
        XCTAssertEqual(self.sut.completionEvent, firstEvent)
    }

    func testCompletionEventResetOnNewMeditationLoad() async {
        // Given - first meditation finishes
        await self.sut.loadAudio()

        let finishedExpectation = self.expectation(description: "completionEvent set")
        self.sut.$completionEvent
            .dropFirst()
            .first { $0 != nil }
            .sink { _ in finishedExpectation.fulfill() }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.finished)
        await fulfillment(of: [finishedExpectation], timeout: 1.0)
        XCTAssertNotNil(self.sut.completionEvent)

        // When - new meditation session starts
        await self.sut.loadAudio()

        // Then - old completion event is cleared
        XCTAssertNil(self.sut.completionEvent)
    }
}

// MARK: - CompletionOverlaySnapshot Tests (AK-6)

final class CompletionOverlaySnapshotTests: XCTestCase {
    func testEvaluatesAsPresentWhenMarkerSet() {
        var snapshot = CompletionOverlaySnapshot()
        snapshot.evaluate(isMarkerSet: true)
        XCTAssertEqual(snapshot.isPresent, true)
    }

    func testEvaluatesAsAbsentWhenNoMarker() {
        var snapshot = CompletionOverlaySnapshot()
        snapshot.evaluate(isMarkerSet: false)
        XCTAssertEqual(snapshot.isPresent, false)
    }

    /// AK-6: Danke-Screen wird nicht doppelt angezeigt wenn Player aktiv ist.
    /// Der Snapshot wird beim Scene-Start ohne Marker ausgewertet (.absent).
    /// Setzt der Player spaeter den Marker, bleibt der Snapshot eingefroren.
    func testSnapshotFrozenAfterFirstEvaluation() {
        // Given - app started without marker (player was already running)
        var snapshot = CompletionOverlaySnapshot()
        snapshot.evaluate(isMarkerSet: false)
        XCTAssertEqual(snapshot.isPresent, false)

        // When - player sets the completion marker mid-session
        snapshot.evaluate(isMarkerSet: true)

        // Then - overlay still not triggered
        XCTAssertEqual(snapshot.isPresent, false)
    }

    func testDismissClearsPresence() {
        var snapshot = CompletionOverlaySnapshot()
        snapshot.evaluate(isMarkerSet: true)
        XCTAssertEqual(snapshot.isPresent, true)

        snapshot.dismiss()

        XCTAssertEqual(snapshot.isPresent, false)
    }

    func testInitialStateIsNil() {
        let snapshot = CompletionOverlaySnapshot()
        XCTAssertNil(snapshot.isPresent)
    }
}

// MARK: - CompletionMarkerWriter Tests (shared-080 AK-2/AK-3)

/// Stand-in for the two `@SceneStorage` values the writer talks to.
/// A class, so the bindings below share one storage instead of copies.
private final class MarkerStorage {
    var completedAt: Double = 0
    var meditationId: String = ""
}

private func makeWriter(_ storage: MarkerStorage) -> CompletionMarkerWriter {
    CompletionMarkerWriter(
        completedAt: Binding(get: { storage.completedAt }, set: { storage.completedAt = $0 }),
        meditationId: Binding(get: { storage.meditationId }, set: { storage.meditationId = $0 })
    )
}

private func makeEvent(completedAt: TimeInterval = 1_700_000_000) -> CompletionEvent {
    CompletionEvent(meditationId: UUID(), completedAt: Date(timeIntervalSince1970: completedAt))
}

final class CompletionMarkerWriterTests: XCTestCase {
    /// A meditation that played to its end is remembered, so the app can show
    /// the completion screen even after the OS terminated it in between.
    func testNaturalEndIsRemembered() {
        let storage = MarkerStorage()
        let writer = makeWriter(storage)
        let event = makeEvent()

        writer.record(event)

        XCTAssertTrue(writer.isSet)
        XCTAssertEqual(storage.completedAt, 1_700_000_000)
        XCTAssertEqual(storage.meditationId, event.meditationId.uuidString)
    }

    /// AK-2: Once the user has tapped away the completion screen, the next app
    /// launch must not show it again.
    func testDismissingCompletionScreenLeavesNothingForTheNextLaunch() {
        let storage = MarkerStorage()
        let writer = makeWriter(storage)
        writer.record(makeEvent())
        var didLeave = false

        writer.dismissCompletionScreen { didLeave = true }

        XCTAssertFalse(writer.isSet)
        XCTAssertEqual(storage.meditationId, "")
        XCTAssertTrue(didLeave, "Dismissing must still navigate away from the completion screen")
    }

    /// AK-3: Starting a new meditation drops a leftover marker.
    func testStartingANewSessionDropsALeftoverMarker() {
        let storage = MarkerStorage()
        let writer = makeWriter(storage)
        writer.record(makeEvent())

        writer.clear()

        XCTAssertFalse(writer.isSet)
        XCTAssertEqual(storage.completedAt, 0)
        XCTAssertEqual(storage.meditationId, "")
    }
}
