//
//  AppDependenciesTests.swift
//  Still Moment
//
//  ios-055: Composition Root — what the app-wide dependency graph guarantees.
//

import XCTest
@testable import StillMoment

@MainActor
final class AppDependenciesTests: XCTestCase {
    func testEachPlayerGetsItsOwnPlaybackService() {
        // Given — the app's dependency graph
        let dependencies = AppDependencies.live()

        // When — two players are opened one after the other
        let first = dependencies.makeAudioPlayerService()
        let second = dependencies.makeAudioPlayerService()

        // Then — playback state of one player never leaks into the next
        XCTAssertFalse(first as AnyObject === second as AnyObject)
    }

    func testEachPlayerGetsItsOwnEndGongPlayer() {
        // Given
        let dependencies = AppDependencies.live()

        // When
        let first = dependencies.makeGongPlayer()
        let second = dependencies.makeGongPlayer()

        // Then — a gong still ringing in a closed player cannot be stopped by the next one
        XCTAssertFalse(first as AnyObject === second as AnyObject)
    }

    func testLiveGraphUsesProductionImplementations() {
        // Given
        let dependencies = AppDependencies.live()

        // Then — the app runs on the real services, not on preview or test doubles
        XCTAssertTrue(dependencies.audioService is AudioService)
        XCTAssertTrue(dependencies.waveformProvider is WaveformProvider)
        XCTAssertTrue(dependencies.meditationService is GuidedMeditationService)
    }
}
