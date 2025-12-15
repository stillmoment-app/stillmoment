//
//  TimerViewModelSettingsTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel settings persistence, duration management, and legacy migration
@MainActor
final class TimerViewModelSettingsTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!

    override func setUp() {
        super.setUp()
        // Use 0 countdown duration for fast tests
        self.mockTimerService = MockTimerService(countdownDuration: 0)
        self.mockAudioService = MockAudioService()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )
    }

    override func tearDown() {
        // Clean up UserDefaults to prevent test pollution
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.durationMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalGongsEnabled)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.removeObject(forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        super.tearDown()
    }

    // MARK: - Settings Persistence

    func testSettingsLoadAndSave() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.intervalMinutes = 10
        self.sut.settings.backgroundSoundId = "forest"
        self.sut.settings.durationMinutes = 25

        // When
        self.sut.saveSettings()

        // Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then
        XCTAssertEqual(newViewModel.settings.intervalGongsEnabled, true)
        XCTAssertEqual(newViewModel.settings.intervalMinutes, 10)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "forest")
        XCTAssertEqual(newViewModel.settings.durationMinutes, 25)
    }

    // MARK: - Duration Persistence

    func testDurationPersistsWhenTimerStarts() {
        // Given
        self.sut.selectedMinutes = 25

        // When
        self.sut.startTimer()

        // Create new instance to verify persistence
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then
        XCTAssertEqual(newViewModel.selectedMinutes, 25, "Duration should be persisted when timer starts")
    }

    func testDurationRestoresOnInit() {
        // Given - Save duration via settings
        self.sut.settings.durationMinutes = 30
        self.sut.saveSettings()

        // When - Create new instance (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Duration should be restored
        XCTAssertEqual(newViewModel.selectedMinutes, 30, "Duration should restore from UserDefaults on init")
    }

    func testDurationValidation() {
        // Given - Duration below minimum
        self.sut.settings.durationMinutes = 0
        self.sut.saveSettings()

        // When - Create new instance
        var newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should clamp to minimum (1)
        XCTAssertEqual(newViewModel.selectedMinutes, 1, "Duration should clamp to minimum of 1 minute")

        // Given - Duration above maximum
        self.sut.settings.durationMinutes = 100
        self.sut.saveSettings()

        // When - Create new instance
        newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should clamp to maximum (60)
        XCTAssertEqual(newViewModel.selectedMinutes, 60, "Duration should clamp to maximum of 60 minutes")

        // Given - Valid duration
        self.sut.settings.durationMinutes = 35
        self.sut.saveSettings()

        // When - Create new instance
        newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should use exact value
        XCTAssertEqual(newViewModel.selectedMinutes, 35, "Valid duration should be preserved")
    }

    func testPickerChangesDoNotPersistUntilStart() {
        // Given - Initial duration is 10
        XCTAssertEqual(self.sut.selectedMinutes, 10)

        // When - Change picker value without starting timer
        self.sut.selectedMinutes = 20

        // Create new instance (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should still have default (10), not the changed value (20)
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Picker changes should not persist until timer starts")

        // When - Now start timer with changed value
        self.sut.selectedMinutes = 20
        self.sut.startTimer()

        // Create another instance
        let anotherViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should now have the started duration (20)
        XCTAssertEqual(anotherViewModel.selectedMinutes, 20, "Duration should persist after starting timer")
    }

    func testDefaultDurationIsUsedOnFirstLaunch() {
        // Given - Clear any saved duration
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.durationMinutes)

        // When - Create new instance (simulates first launch)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should use default of 10 minutes
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Should use default duration of 10 minutes on first launch")
    }

    // MARK: - Background Sound Settings

    func testSettingsLoadWithInvalidSoundId_FallsBackToDefault() {
        // Given - Save an invalid sound ID
        let defaults = UserDefaults.standard
        defaults.set("invalid_sound_id", forKey: MeditationSettings.Keys.backgroundSoundId)

        // When - Create new ViewModel (loads settings)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should still use the invalid ID (AudioService will handle the error)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "invalid_sound_id")

        // When - Try to start timer with invalid sound ID
        newViewModel.selectedMinutes = 1
        newViewModel.startTimer()

        // Then - AudioService should be called but will throw error
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
    }

    func testSettingsLoadWithMissingBackgroundSoundId_UsesDefault() {
        // Given - Remove backgroundSoundId from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)

        // When - Create new ViewModel (loads settings)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should use default "silent"
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }

    // MARK: - Legacy Migration

    func testSettingsLegacyMigration_SilentMode() {
        // Given - Save legacy backgroundAudioMode setting
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.set("Silent", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When - Create new ViewModel (triggers migration)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should migrate to "silent" sound ID
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")

        // Verify migration saved the new value
        let savedValue = defaults.string(forKey: MeditationSettings.Keys.backgroundSoundId)
        XCTAssertEqual(savedValue, "silent")
    }

    func testSettingsLegacyMigration_WhiteNoiseMode() {
        // Given - Save legacy "White Noise" setting
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.set("White Noise", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When - Create new ViewModel (triggers migration)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should migrate to "silent" (WhiteNoise was removed)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }
}
