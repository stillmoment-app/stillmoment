//
//  TimerViewModelSettingsTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel settings persistence, duration management, and repository integration.
///
/// Architecture note: since shared-068, settings are loaded from `PraxisRepository` at init,
/// not from `TimerSettingsRepository`. The `TimerSettingsRepository` is still written to during
/// a session (e.g. via `saveSettings()`), but new VM instances load their initial state from
/// the Praxis. Tests therefore inject a `MockPraxisRepository` to control initial state.
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
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPraxisRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()
        self.mockPraxisRepository = MockPraxisRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        self.mockPraxisRepository = nil
        super.tearDown()
    }

    // MARK: - Repository Integration

    func testInit_usesSettingsFromPraxisRepository() {
        // Given: praxis repository has specific settings
        let praxis = Praxis(
            durationMinutes: 25,
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            backgroundSoundId: "forest"
        )
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = praxis

        // When: create new ViewModel
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: ViewModel should have the praxis's settings
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

    // MARK: - Settings Persistence (via praxisRepository)

    func testSettingsLoadAndSave() {
        // Given: praxis repository has specific settings
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(
            durationMinutes: 25,
            intervalGongsEnabled: true,
            intervalMinutes: 10,
            backgroundSoundId: "forest"
        )

        // When: Create instance from the repository (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then
        XCTAssertEqual(newViewModel.settings.intervalGongsEnabled, true)
        XCTAssertEqual(newViewModel.settings.intervalMinutes, 10)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "forest")
        XCTAssertEqual(newViewModel.selectedMinutes, 25)
    }

    // MARK: - Duration Persistence

    func testDurationPersistsWhenTimerStarts() {
        // Given: praxis has duration 25
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(durationMinutes: 25)

        // When: Create VM from repository
        let viewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: selectedMinutes reflects stored duration
        XCTAssertEqual(viewModel.selectedMinutes, 25, "Duration should be persisted when timer starts")
    }

    func testDurationRestoresOnInit() {
        // Given: praxis repository has duration 30
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(durationMinutes: 30)

        // When: Create new instance (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: Duration should be restored
        XCTAssertEqual(newViewModel.selectedMinutes, 30, "Duration should restore from repository on init")
    }

    func testPickerChangesDoNotPersistUntilStart() {
        // Given: Initial duration from default praxis is 10
        XCTAssertEqual(self.sut.selectedMinutes, 10)

        // When: Change picker value without starting timer
        self.sut.selectedMinutes = 20

        // Create new instance from same praxis repo (simulates app restart before timer starts)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )

        // Then: Should still have default (10) from stored praxis, not the changed value
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Picker changes should not persist until saved via praxis")
    }

    func testDefaultDurationIsUsedOnFirstLaunch() {
        // Given: Fresh praxis repository (default Praxis has duration 10)
        let freshPraxisRepo = MockPraxisRepository()

        // When: Create new instance (simulates first launch)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: MockTimerSettingsRepository(),
            praxisRepository: freshPraxisRepo
        )

        // Then: Should use default of 10 minutes
        XCTAssertEqual(newViewModel.selectedMinutes, 10, "Should use default duration of 10 minutes on first launch")
    }

    // MARK: - Background Sound Settings

    func testSettingsLoadWithInvalidSoundId() {
        // Given: praxis repository has praxis with invalid sound ID
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(backgroundSoundId: "invalid_sound_id")

        // When: Create new ViewModel (loads settings from praxis)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: Should still use the invalid ID (AudioService will handle the error)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "invalid_sound_id")

        // When: Start timer and transition through startGong to running
        newViewModel.selectedMinutes = 1
        newViewModel.startTimer()
        newViewModel.dispatch(.preparationFinished)
        newViewModel.timer = .stub(durationMinutes: 1, state: .startGong)
        newViewModel.dispatch(.startGongFinished)

        // Then: AudioService should be called but will throw error
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
    }

    func testDefaultBackgroundSoundId() {
        // Given: Fresh praxis repository (default Praxis has backgroundSoundId "silent")
        let freshPraxisRepo = MockPraxisRepository()

        // When: Create new ViewModel
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: MockTimerSettingsRepository(),
            praxisRepository: freshPraxisRepo
        )

        // Then: Should use default "silent"
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }

    // MARK: - Background Volume Settings

    func testBackgroundSoundVolume_persistence() {
        // Given: praxis repository has praxis with custom volume
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(backgroundSoundVolume: 0.75)

        // When: Create VM from repository
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: Volume should be restored
        XCTAssertEqual(newViewModel.settings.backgroundSoundVolume, 0.75, accuracy: 0.001)
    }

    func testBackgroundSoundVolume_defaultValue() {
        // Given: Fresh praxis repository (Praxis.default has 0.15)
        let freshPraxisRepo = MockPraxisRepository()

        // When: Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: MockTimerSettingsRepository(),
            praxisRepository: freshPraxisRepo
        )

        // Then: Should use default (0.15)
        XCTAssertEqual(
            newViewModel.settings.backgroundSoundVolume,
            MeditationSettings.defaultBackgroundSoundVolume,
            accuracy: 0.001
        )
    }

    func testStartTimer_passesVolumeToAudioService() {
        // Given: Set custom volume and sound
        self.sut.settings.backgroundSoundId = "forest"
        self.sut.settings.backgroundSoundVolume = 0.5
        self.sut.selectedMinutes = 5

        // When: Start timer and transition through startGong to running
        self.sut.startTimer()
        self.sut.dispatch(.preparationFinished)
        self.sut.timer = .stub(durationMinutes: 5, state: .startGong)
        self.sut.dispatch(.startGongFinished)

        // Then: AudioService should receive the correct volume
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
        // Given: praxis with custom gong volume
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(gongVolume: 0.6)

        // When: Create VM from repository
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: Volume should be restored
        XCTAssertEqual(newViewModel.settings.gongVolume, 0.6, accuracy: 0.001)
    }

    func testGongVolume_defaultValue() {
        // Given: Fresh praxis repository
        let freshPraxisRepo = MockPraxisRepository()

        // When: Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: MockTimerSettingsRepository(),
            praxisRepository: freshPraxisRepo
        )

        // Then: Should use default (1.0 = 100%)
        XCTAssertEqual(
            newViewModel.settings.gongVolume,
            MeditationSettings.defaultGongVolume,
            accuracy: 0.001
        )
    }

    func testStartTimer_passesGongVolumeToAudioService() {
        // Given: Set custom gong volume
        self.sut.settings.gongVolume = 0.7
        self.sut.selectedMinutes = 5

        // When: Start timer and trigger preparationFinished (which plays the gong)
        self.sut.startTimer()
        self.sut.dispatch(.preparationFinished)

        // Then: AudioService should receive the correct gong volume
        XCTAssertTrue(self.mockAudioService.playStartGongCalled)
        XCTAssertEqual(
            Double(self.mockAudioService.lastStartGongVolume ?? 0),
            0.7,
            accuracy: 0.001
        )
    }

    // MARK: - Preparation Time Settings

    func testPreparationTimeSettings_defaultValues() {
        // Given: Fresh praxis repository (Praxis.default has preparationTimeEnabled=true, 15s)
        let freshPraxisRepo = MockPraxisRepository()

        // When: Create new instance (simulates first launch)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: MockTimerSettingsRepository(),
            praxisRepository: freshPraxisRepo
        )

        // Then: Should use defaults: enabled with 15 seconds
        XCTAssertTrue(newViewModel.settings.preparationTimeEnabled)
        XCTAssertEqual(newViewModel.settings.preparationTimeSeconds, 15)
    }

    func testPreparationTimeSettings_persistence() {
        // Given: praxis with custom preparation settings
        let praxisRepo = MockPraxisRepository()
        praxisRepo.currentPraxis = Praxis(preparationTimeEnabled: false, preparationTimeSeconds: 30)

        // When: Create VM from repository (simulates app restart)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: praxisRepo
        )

        // Then: Settings should be restored
        XCTAssertFalse(newViewModel.settings.preparationTimeEnabled)
        XCTAssertEqual(newViewModel.settings.preparationTimeSeconds, 30)
    }

    func testStartTimer_withPreparationEnabled_passesPreparationTime() {
        // Given: Preparation enabled with specific duration
        self.sut.settings.preparationTimeEnabled = true
        self.sut.settings.preparationTimeSeconds = 20
        self.sut.selectedMinutes = 5

        // When: Start timer
        self.sut.startTimer()

        // Then: Timer service should receive the preparation time
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 5)
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 20)
    }

    func testStartTimer_withPreparationDisabled_passesZeroPreparationTime() {
        // Given: Preparation disabled
        self.sut.settings.preparationTimeEnabled = false
        self.sut.settings.preparationTimeSeconds = 20 // Should be ignored
        self.sut.selectedMinutes = 5

        // When: Start timer
        self.sut.startTimer()

        // Then: Timer service should receive 0 for preparation time
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 5)
        XCTAssertEqual(self.mockTimerService.lastStartPreparationTime, 0)
    }

    func testStartTimer_withPreparationDisabled_playsStartGong() {
        // Given: Preparation disabled
        self.sut.settings.preparationTimeEnabled = false
        self.sut.selectedMinutes = 5

        // When: Start timer and manually trigger the state transition effect
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
        // Given: Preparation enabled
        self.sut.settings.preparationTimeEnabled = true
        self.sut.settings.preparationTimeSeconds = 15
        self.sut.selectedMinutes = 5

        // When: Start timer and manually trigger the state transition effect
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

    // MARK: - Introduction Duration Restoration

    func testDisablingIntroduction_restoresPreIntroductionDuration() {
        // Given: User selects 1 minute
        self.sut.selectedMinutes = 1
        XCTAssertEqual(self.sut.selectedMinutes, 1)

        // When: Enable introduction (requires minimum 2 minutes, ceil(95/60))
        self.sut.settings.introductionEnabled = true
        self.sut.settings.introductionId = "breath"

        // Then: Duration should be clamped to minimum
        XCTAssertEqual(self.sut.selectedMinutes, 2, "Should clamp to introduction minimum")

        // When: Disable introduction
        self.sut.settings.introductionId = nil

        // Then: Duration should restore to the pre-introduction value
        XCTAssertEqual(self.sut.selectedMinutes, 1, "Should restore to pre-introduction duration")
    }

    func testDisablingIntroduction_noRestoreWhenDurationWasAboveMinimum() {
        // Given: User selects 10 minutes (already above the 3-minute minimum)
        self.sut.selectedMinutes = 10

        // When: Enable introduction
        self.sut.settings.introductionEnabled = true
        self.sut.settings.introductionId = "breath"

        // Then: Duration should stay at 10 (already above minimum)
        XCTAssertEqual(self.sut.selectedMinutes, 10, "Should not change when already above minimum")

        // When: Disable introduction
        self.sut.settings.introductionId = nil

        // Then: Duration should still be 10
        XCTAssertEqual(self.sut.selectedMinutes, 10, "Should stay at 10 when no clamping occurred")
    }

    // MARK: - Settings Hint Persistence (Onboarding)

    // Note: hasSeenSettingsHint is @AppStorage in the View (Presentation Layer)
    // These tests verify the UserDefaults behavior directly, not via the repository

    func testSettingsHint_defaultIsFalse() {
        // Given: Clear any saved hint state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasSeenSettingsHint")

        // When: Read the value
        let hasSeenHint = defaults.bool(forKey: "hasSeenSettingsHint")

        // Then: Should be false (not seen yet)
        XCTAssertFalse(hasSeenHint, "Default hint state should be false (not seen)")
    }

    func testSettingsHint_persistsWhenSetToTrue() {
        // Given: Clear any saved hint state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasSeenSettingsHint")

        // When: Set hint as seen
        defaults.set(true, forKey: "hasSeenSettingsHint")

        // Then: Should persist
        let hasSeenHint = defaults.bool(forKey: "hasSeenSettingsHint")
        XCTAssertTrue(hasSeenHint, "Hint state should persist as true after being set")
    }

    func testSettingsHint_survivesAppRestart() {
        // Given: Set hint as seen
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "hasSeenSettingsHint")
        defaults.synchronize()

        // When: Simulate app restart by reading from fresh defaults access
        let hasSeenHint = UserDefaults.standard.bool(forKey: "hasSeenSettingsHint")

        // Then: Should still be true
        XCTAssertTrue(hasSeenHint, "Hint state should survive simulated app restart")
    }
}
