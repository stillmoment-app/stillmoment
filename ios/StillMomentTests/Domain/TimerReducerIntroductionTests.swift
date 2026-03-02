//
//  TimerReducerIntroductionTests.swift
//  Still Moment
//
//  Tests for TimerReducer introduction-related effect mapping.
//

import XCTest
@testable import StillMoment

final class TimerReducerIntroductionTests: XCTestCase {
    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Force German locale so "breath" introduction is always available
        Introduction.languageOverride = "de"
    }

    override func tearDown() {
        Introduction.languageOverride = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private var defaultSettings: MeditationSettings {
        MeditationSettings.default
    }

    /// Settings with introduction configured and enabled
    private var settingsWithIntroduction: MeditationSettings {
        MeditationSettings(introductionId: "breath", introductionEnabled: true)
    }

    /// Settings with introduction configured but disabled
    private var settingsWithIntroductionDisabled: MeditationSettings {
        MeditationSettings(introductionId: "breath", introductionEnabled: false)
    }

    // MARK: - StartPressed with Introduction

    func testStartPressed_withoutIntroduction_doesNotIncludeBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.defaultSettings
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

    func testStartPressed_withIntroduction_delaysBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startPressed,
            timerState: .idle,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        // Then - No background audio yet (delayed until introduction finishes)
        let hasBackgroundAudio = effects.contains { effect in
            if case .startBackgroundAudio = effect {
                return true
            }
            return false
        }
        XCTAssertFalse(hasBackgroundAudio, "Background audio should be delayed when introduction is active")
    }

    // MARK: - PreparationFinished with Introduction

    func testPreparationFinished_withIntroduction_playsStartGong() {
        // When
        let effects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertEqual(effects, [.playStartGong])
    }

    func testPreparationFinished_withoutIntroduction_playsStartGong() {
        // When
        let effects = TimerReducer.reduce(
            action: .preparationFinished,
            timerState: .preparation,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertEqual(effects, [.playStartGong])
    }

    // MARK: - StartGongFinished

    func testStartGongFinished_withIntroduction_playsIntroduction() {
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertEqual(effects, [.beginIntroductionPhase, .playIntroduction(introductionId: "breath")])
    }

    func testStartGongFinished_withoutIntroduction_startsBackgroundAudio() {
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
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
            settings: self.settingsWithIntroduction
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringIntroduction_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .introduction,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        XCTAssertTrue(effects.isEmpty)
    }

    func testStartGongFinished_duringRunning_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - IntroductionFinished

    func testIntroductionFinished_producesStopAndStartEffects() {
        // When
        let effects = TimerReducer.reduce(
            action: .introductionFinished,
            timerState: .introduction,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.endIntroductionPhase))
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.settingsWithIntroduction.backgroundSoundId,
            volume: self.settingsWithIntroduction.backgroundSoundVolume
        )))
    }

    func testIntroductionFinished_startsBackgroundAudioWithCorrectSettings() {
        // Given
        let settings = MeditationSettings(
            backgroundSoundId: "forest",
            backgroundSoundVolume: 0.3,
            introductionId: "breath"
        )

        // When
        let effects = TimerReducer.reduce(
            action: .introductionFinished,
            timerState: .introduction,
            selectedMinutes: 10,
            settings: settings
        )

        // Then
        XCTAssertTrue(effects.contains(.startBackgroundAudio(soundId: "forest", volume: 0.3)))
    }

    func testIntroductionFinished_fromNonIntroductionState_isNoOp() {
        let effects = TimerReducer.reduce(
            action: .introductionFinished,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - TimerCompleted with Introduction

    func testTimerCompleted_fromIntroduction_stopsIntroduction() {
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .introduction,
            selectedMinutes: 3,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.contains(.playCompletionSound))
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertFalse(effects.contains(.deactivateTimerSession))
    }

    func testTimerCompleted_fromRunning_doesNotStopIntroduction() {
        // When
        let effects = TimerReducer.reduce(
            action: .timerCompleted,
            timerState: .running,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertFalse(effects.contains(.stopIntroduction))
        XCTAssertEqual(effects, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - ResetPressed with Introduction

    func testResetPressed_fromIntroduction_stopsIntroduction() {
        // When
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .introduction,
            selectedMinutes: 10,
            settings: self.settingsWithIntroduction
        )

        // Then
        XCTAssertTrue(effects.contains(.stopIntroduction))
        XCTAssertTrue(effects.contains(.stopBackgroundAudio))
        XCTAssertTrue(effects.contains(.resetTimer))
    }

    func testResetPressed_fromStartGong_doesNotStopIntroduction() {
        // When
        let effects = TimerReducer.reduce(
            action: .resetPressed,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.defaultSettings
        )

        // Then
        XCTAssertFalse(effects.contains(.stopIntroduction))
        XCTAssertEqual(effects, [.stopBackgroundAudio, .resetTimer, .clearTimer, .deactivateTimerSession])
    }

    // MARK: - Introduction Disabled Behavior

    func testStartGongFinished_withIntroductionDisabled_startsBackgroundAudio() {
        // Given - Introduction is set but disabled
        // When
        let effects = TimerReducer.reduce(
            action: .startGongFinished,
            timerState: .startGong,
            selectedMinutes: 10,
            settings: self.settingsWithIntroductionDisabled
        )

        // Then - Should skip introduction and start background audio directly
        XCTAssertFalse(effects.contains(.beginIntroductionPhase))
        XCTAssertTrue(effects.contains(.startBackgroundAudio(
            soundId: self.settingsWithIntroductionDisabled.backgroundSoundId,
            volume: self.settingsWithIntroductionDisabled.backgroundSoundVolume
        )))
    }
}
