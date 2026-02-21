//
//  TimerViewModelSettingsTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel settings persistence, duration management, and repository integration
@MainActor
final class TimerViewModelSettingsTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSettingsRepository: MockTimerSettingsRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        super.tearDown()
    }

    // MARK: - Repository Integration

    func testInit_loadsSettingsFromRepository() {
        // Then - Repository should have been called on init
        XCTAssertTrue(self.mockSettingsRepository.loadCalled)
        XCTAssertEqual(self.mockSettingsRepository.loadCallCount, 1)
    }

    func testInit_usesSettingsFromRepository() {
        // Given - Configure repository to return custom settings
        let customSettings = MeditationSettings(
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            backgroundSoundId: "forest",
            durationMinutes: 25
        )
        let repository = MockTimerSettingsRepository()
        repository.settingsToReturn = customSettings

        // When - Create new ViewModel
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: repository
        )

        // Then - ViewModel should have the repository's settings
        XCTAssertEqual(viewModel.settings.intervalGongsEnabled, true)
        XCTAssertEqual(viewModel.settings.intervalMinutes, 10)
        XCTAssertEqual(viewModel.settings.backgroundSoundId, "forest")
        XCTAssertEqual(viewModel.settings.durationMinutes, 25)
    }

    func testSaveSettings_delegatesToRepository() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.backgroundSoundId = "forest"

        // When
        self.sut.saveSettings()

        // Then
        XCTAssertTrue(self.mockSettingsRepository.saveCalled)
        XCTAssertEqual(self.mockSettingsRepository.saveCallCount, 1)
        XCTAssertEqual(self.mockSettingsRepository.lastSavedSettings?.intervalGongsEnabled, true)
        XCTAssertEqual(self.mockSettingsRepository.lastSavedSettings?.backgroundSoundId, "forest")
    }

    // MARK: - Settings Persistence (via shared repository)

    func testSettingsLoadAndSave() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.intervalMinutes = 10
        self.sut.settings.backgroundSoundId = "forest"
        self.sut.settings.durationMinutes = 25

        // When
        self.sut.saveSettings()

        // Create new instance with same repository (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
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
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
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
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Duration should be restored
        XCTAssertEqual(newViewModel.selectedMinutes, 30, "Duration should restore from repository on init")
    }

    func testPickerChangesDoNotPersistUntilStart() {
        // Given - Initial duration is 10
        XCTAssertEqual(self.sut.selectedMinutes, 10)

        // When - Change picker value without starting timer
        self.sut.selectedMinutes = 20

        // Create new instance (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Should still have default (10), not the changed value (20)
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Picker changes should not persist until timer starts")

        // When - Now start timer with changed value
        self.sut.selectedMinutes = 20
        self.sut.startTimer()

        // Create another instance
        let anotherViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Should now have the started duration (20)
        XCTAssertEqual(anotherViewModel.selectedMinutes, 20, "Duration should persist after starting timer")
    }

    func testDefaultDurationIsUsedOnFirstLaunch() {
        // Given - Repository returns default settings (first launch scenario)
        let freshRepository = MockTimerSettingsRepository()

        // When - Create new instance (simulates first launch)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: freshRepository
        )

        // Then - Should use default of 10 minutes
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Should use default duration of 10 minutes on first launch")
    }

    // MARK: - Background Sound Settings

    func testSettingsLoadWithInvalidSoundId() {
        // Given - Repository returns settings with invalid sound ID
        let repository = MockTimerSettingsRepository()
        repository.settingsToReturn = MeditationSettings(backgroundSoundId: "invalid_sound_id")

        // When - Create new ViewModel (loads settings)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: repository
        )

        // Then - Should still use the invalid ID (AudioService will handle the error)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "invalid_sound_id")

        // When - Start timer and transition through startGong to running
        newViewModel.selectedMinutes = 1
        newViewModel.startTimer()
        newViewModel.dispatch(.preparationFinished)
        newViewModel.dispatch(.startGongFinished)

        // Then - AudioService should be called but will throw error
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
    }

    func testDefaultBackgroundSoundId() {
        // Given - Repository returns default settings
        let freshRepository = MockTimerSettingsRepository()

        // When - Create new ViewModel
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: freshRepository
        )

        // Then - Should use default "silent"
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }

    // MARK: - Background Volume Settings

    func testBackgroundSoundVolume_persistence() {
        // Given - Set custom volume
        self.sut.settings.backgroundSoundVolume = 0.75

        // When - Save and create new instance
        self.sut.saveSettings()
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Volume should be restored
        XCTAssertEqual(newViewModel.settings.backgroundSoundVolume, 0.75, accuracy: 0.001)
    }

    func testBackgroundSoundVolume_defaultValue() {
        // Given - Repository returns default settings
        let freshRepository = MockTimerSettingsRepository()

        // When - Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: freshRepository
        )

        // Then - Should use default (0.15)
        XCTAssertEqual(
            newViewModel.settings.backgroundSoundVolume,
            MeditationSettings.defaultBackgroundSoundVolume,
            accuracy: 0.001
        )
    }

    func testStartTimer_passesVolumeToAudioService() {
        // Given - Set custom volume and sound
        self.sut.settings.backgroundSoundId = "forest"
        self.sut.settings.backgroundSoundVolume = 0.5
        self.sut.selectedMinutes = 5

        // When - Start timer and transition through startGong to running
        self.sut.startTimer()
        self.sut.dispatch(.preparationFinished)
        self.sut.dispatch(.startGongFinished)

        // Then - AudioService should receive the correct volume
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
        XCTAssertEqual(self.mockAudioService.lastStartBackgroundAudioSoundId, "forest")
        XCTAssertEqual(
            Double(self.mockAudioService.lastStartBackgroundAudioVolume ?? 0),
            0.5,
            accuracy: 0.001
        )
    }

    // MARK: - Gong Volume Settings

    func testGongVolume_persistence() {
        // Given - Set custom gong volume
        self.sut.settings.gongVolume = 0.6

        // When - Save and create new instance
        self.sut.saveSettings()
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Volume should be restored
        XCTAssertEqual(newViewModel.settings.gongVolume, 0.6, accuracy: 0.001)
    }

    func testGongVolume_defaultValue() {
        // Given - Repository returns default settings
        let freshRepository = MockTimerSettingsRepository()

        // When - Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: freshRepository
        )

        // Then - Should use default (1.0 = 100%)
        XCTAssertEqual(
            newViewModel.settings.gongVolume,
            MeditationSettings.defaultGongVolume,
            accuracy: 0.001
        )
    }

    func testStartTimer_passesGongVolumeToAudioService() {
        // Given - Set custom gong volume
        self.sut.settings.gongVolume = 0.7
        self.sut.selectedMinutes = 5

        // When - Start timer and trigger preparationFinished (which plays the gong)
        self.sut.startTimer()
        self.sut.dispatch(.preparationFinished)

        // Then - AudioService should receive the correct gong volume
        XCTAssertTrue(self.mockAudioService.playStartGongCalled)
        XCTAssertEqual(
            Double(self.mockAudioService.lastStartGongVolume ?? 0),
            0.7,
            accuracy: 0.001
        )
    }

    // MARK: - Preparation Time Settings

    func testPreparationTimeSettings_defaultValues() {
        // Given - Repository returns default settings
        let freshRepository = MockTimerSettingsRepository()

        // When - Create new instance (simulates first launch)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: freshRepository
        )

        // Then - Should use defaults: enabled with 15 seconds
        XCTAssertTrue(newViewModel.settings.preparationTimeEnabled)
        XCTAssertEqual(newViewModel.settings.preparationTimeSeconds, 15)
    }

    func testPreparationTimeSettings_persistence() {
        // Given - Configure preparation settings
        self.sut.settings.preparationTimeEnabled = false
        self.sut.settings.preparationTimeSeconds = 30

        // When - Save and create new instance
        self.sut.saveSettings()
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )

        // Then - Settings should be restored
        XCTAssertFalse(newViewModel.settings.preparationTimeEnabled)
        XCTAssertEqual(newViewModel.settings.preparationTimeSeconds, 30)
    }

    func testStartTimer_withPreparationEnabled_passesPreparationTime() {
        // Given - Preparation enabled with specific duration
        self.sut.settings.preparationTimeEnabled = true
        self.sut.settings.preparationTimeSeconds = 20
        self.sut.selectedMinutes = 5

        // When - Start timer
        self.sut.startTimer()

        // Then - Timer service should receive the preparation time
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 5)
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 20)
    }

    func testStartTimer_withPreparationDisabled_passesZeroPreparationTime() {
        // Given - Preparation disabled
        self.sut.settings.preparationTimeEnabled = false
        self.sut.settings.preparationTimeSeconds = 20 // Should be ignored
        self.sut.selectedMinutes = 5

        // When - Start timer
        self.sut.startTimer()

        // Then - Timer service should receive 0 for preparation time
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 5)
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 0)
    }

    func testStartTimer_withPreparationDisabled_playsStartGong() {
        // Given - Preparation disabled
        self.sut.settings.preparationTimeEnabled = false
        self.sut.selectedMinutes = 5

        // When - Start timer and manually trigger the state transition effect
        self.sut.startTimer()

        // Verify correct preparation time was passed
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 0)

        // Simulate the effect of idle → startGong transition
        self.sut.dispatch(.preparationFinished)

        // Then
        XCTAssertTrue(
            self.mockAudioService.playStartGongCalled,
            "Start gong should play when preparationFinished is dispatched"
        )
    }

    func testStartTimer_withPreparationEnabled_playsStartGongAfterPreparation() {
        // Given - Preparation enabled
        self.sut.settings.preparationTimeEnabled = true
        self.sut.settings.preparationTimeSeconds = 15
        self.sut.selectedMinutes = 5

        // When - Start timer and manually trigger the state transition effect
        self.sut.startTimer()

        // Verify correct preparation time was passed
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 15)

        // Simulate the effect of preparation → running transition
        self.sut.dispatch(.preparationFinished)

        // Then
        XCTAssertTrue(
            self.mockAudioService.playStartGongCalled,
            "Start gong should play when meditation begins"
        )
    }

    // MARK: - Settings Hint Persistence (Onboarding)

    // Note: hasSeenSettingsHint is @AppStorage in the View (Presentation Layer)
    // These tests verify the UserDefaults behavior directly, not via the repository

    func testSettingsHint_defaultIsFalse() {
        // Given - Clear any saved hint state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasSeenSettingsHint")

        // When - Read the value
        let hasSeenHint = defaults.bool(forKey: "hasSeenSettingsHint")

        // Then - Should be false (not seen yet)
        XCTAssertFalse(hasSeenHint, "Default hint state should be false (not seen)")
    }

    func testSettingsHint_persistsWhenSetToTrue() {
        // Given - Clear any saved hint state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasSeenSettingsHint")

        // When - Set hint as seen
        defaults.set(true, forKey: "hasSeenSettingsHint")

        // Then - Should persist
        let hasSeenHint = defaults.bool(forKey: "hasSeenSettingsHint")
        XCTAssertTrue(hasSeenHint, "Hint state should persist as true after being set")
    }

    func testSettingsHint_survivesAppRestart() {
        // Given - Set hint as seen
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "hasSeenSettingsHint")
        defaults.synchronize()

        // When - Simulate app restart by reading from fresh defaults access
        let hasSeenHint = UserDefaults.standard.bool(forKey: "hasSeenSettingsHint")

        // Then - Should still be true
        XCTAssertTrue(hasSeenHint, "Hint state should survive simulated app restart")
    }
}
