//
//  TimerReducerAttunementTests.swift
//  Still Moment
//
//  Tests for TimerReducer attunement-related effect mapping.
//

import XCTest
@testable import StillMoment

final class TimerReducerAttunementTests: XCTestCase {
    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    /// Resolver that resolves "breath" to a valid attunement (for attunement tests)
    private var breathResolver: MockAttunementResolver {
        let resolver = MockAttunementResolver()
        resolver.stubbedResolveResults["breath"] = ResolvedAttunement(
            id: "breath",
            displayName: "Breath",
            durationSeconds: 120
        )
        return resolver
    }

    /// Resolver that resolves nothing (for non-attunement tests)
    private var emptyResolver: MockAttunementResolver {
        MockAttunementResolver()
    }

    /// Settings with attunement configured and enabled
    private var settingsWithAttunement: MeditationSettings {
        MeditationSettings(attunementId: "breath", attunementEnabled: true)
    }

    /// Settings with attunement configured but disabled
    private var settingsWithAttunementDisabled: MeditationSettings {
        MeditationSettings(attunementId: "breath", attunementEnabled: false)
    }

    // MARK: - StartPressed with Attunement

    func testStartPressed_withoutAttunement_doesNotIncludeBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then - Background audio is NOT started here; it starts in startGongFinished
        let hasBackgroundAudio = effects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        }
        XCTAssertFalse(hasBackgroundAudio, "Background audio should start in startGongFinished, not startPressed")
    }

    func testStartPressed_withAttunement_delaysBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then - No background audio yet (delayed until attunement finishes)
        let hasBackgroundAudio = effects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        }
        XCTAssertFalse(hasBackgroundAudio, "Background audio should be delayed when attunement is active")
    }

    // MARK: - PreparationFinished with Attunement

    func testPreparationFinished_withAttunement_playsStartGong() {
        // When
        let effects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertEqual(effects, [.playStartGong])
    }

    func testPreparationFinished_withoutAttunement_playsStartGong() {
        // When
        let effects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertEqual(effects, [.playStartGong])
    }

    // MARK: - StartGongFinished

    func testStartGongFinished_withAttunement_playsAttunement() {
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertEqual(effects, [.beginAttunementPhase, .playAttunement(attunementId: "breath")])
    }

    func testStartGongFinished_withoutAttunement_startsBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.defaultSettings.backgroundSoundId,
            volume: self.defaultSettings.backgroundSoundVolume
        )))
    }

    func testStartGongFinished_duringCompleted_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .completed,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringAttunement_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .attunement,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringRunning_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - AttunementFinished

    func testAttunementFinished_producesStopAndStartEffects() {
        // When
        let effects = TimerReducer.reduce(
            action: .attunementFinished,
            timerState: .attunement,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.stopAttunement))
        XCTAssertTrue(effects.contains(.endAttunementPhase))
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.settingsWithAttunement.backgroundSoundId,
            volume: self.settingsWithAttunement.backgroundSoundVolume
        )))
    }

    func testAttunementFinished_startsBackgroundAudioWithCorrectSettings() {
        // Given
        let settings = MeditationSettings(
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3,
            attunementId: "breath"
        )

        // When
        let effects = TimerReducer.reduce(
            action: .attunementFinished,
            timerState: .attunement,
            selectedMinutes: 10,
            settings: settings,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.startBackgroundAudio(soundId: "forest", volume: 0.3)))
    }

    func testAttunementFinished_fromNonAttunementState_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .attunementFinished,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - TimerCompleted with Attunement

    func testTimerCompleted_fromAttunement_stopsAttunement() {
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .attunement,
            selectedMinutes: 3,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.playCompletionSound))
        XCTAssertTrue(effects.contains(.stopAttunement))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    func testTimerCompleted_fromRunning_doesNotStopAttunement() {
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertFalse(effects.contains(.stopAttunement))
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - ResetPressed with Attunement

    func testResetPressed_fromAttunement_stopsAttunement() {
        // When
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .attunement,
            selectedMinutes: 10,
            settings: self.settingsWithAttunement,
            attunementResolver: self.breathResolver
        )

        // Then
        XCTAssertTrue(effects.contains(.stopAttunement))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    func testResetPressed_fromStartGong_doesNotStopAttunement() {
        // When
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings,
            attunementResolver: self.emptyResolver
        )

        // Then
        XCTAssertFalse(effects.contains(.stopAttunement))
        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer, .clearTimer, .deactivateTimerSession])
    }

    // MARK: - Attunement Disabled Behavior

    func testStartGongFinished_withAttunementDisabled_startsBackgroundAudio() {
        // Given - Attunement is set but disabled
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.settingsWithAttunementDisabled,
            attunementResolver: self.breathResolver
        )

        // Then - Should skip attunement and start background audio directly
        XCTAssertFalse(effects.contains(.beginAttunementPhase))
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.settingsWithAttunementDisabled.backgroundSoundId,
            volume: self.settingsWithAttunementDisabled.backgroundSoundVolume
        )))
    }
}
