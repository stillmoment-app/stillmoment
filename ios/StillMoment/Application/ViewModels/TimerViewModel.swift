//
//  TimerViewModel.swift
//  Still Moment
//
//  Application Layer - Timer ViewModel with Reducer Pattern
//

import Combine
import Foundation
import OSLog

/// ViewModel managing timer state using unidirectional data flow
///
/// This ViewModel uses the Reducer pattern:
/// 1. View dispatches actions
/// 2. Reducer produces new state + effects
/// 3. Effects are executed by the effect handler
/// 4. State changes trigger view updates
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        timerService: TimerServiceProtocol = TimerService(),
        audioService: AudioServiceProtocol = AudioService()
    ) {
        self.timerService = timerService
        self.audioService = audioService

        self.loadSettings()
        // Initialize display state with saved duration
        self.displayState = TimerDisplayState.withDuration(minutes: self.settings.durationMinutes)
        self.setupBindings()
    }

    // MARK: Internal

    // MARK: - Published State

    /// The complete display state managed by the reducer
    @Published private(set) var displayState: TimerDisplayState = .initial

    /// Meditation settings (interval gongs, background sound, etc.)
    @Published var settings: MeditationSettings = .default

    /// Error message if any operation fails
    @Published var errorMessage: String?

    // MARK: - Computed Properties (Forwarded from DisplayState)

    /// Current timer state
    var timerState: TimerState { self.displayState.timerState }

    /// Selected duration in minutes
    var selectedMinutes: Int {
        get { self.displayState.selectedMinutes }
        set { self.dispatch(.selectDuration(minutes: newValue)) }
    }

    /// Remaining time in seconds
    var remainingSeconds: Int { self.displayState.remainingSeconds }

    /// Total duration in seconds
    var totalSeconds: Int { self.displayState.totalSeconds }

    /// Progress value (0.0 - 1.0)
    var progress: Double { self.displayState.progress }

    /// Remaining preparation seconds
    var remainingPreparationSeconds: Int { self.displayState.remainingPreparationSeconds }

    /// Current affirmation index
    var currentAffirmationIndex: Int { self.displayState.currentAffirmationIndex }

    /// Whether currently in preparation phase
    var isPreparation: Bool { self.displayState.isPreparation }

    /// Returns true if timer can be started
    var canStart: Bool { self.displayState.canStart }

    /// Returns true if timer can be paused
    var canPause: Bool { self.displayState.canPause }

    /// Returns true if timer can be resumed
    var canResume: Bool { self.displayState.canResume }

    /// Formatted time string
    var formattedTime: String { self.displayState.formattedTime }

    /// Get current running affirmation
    var currentRunningAffirmation: String {
        self.runningAffirmations[self.displayState.currentAffirmationIndex % self.runningAffirmations.count]
    }

    /// Get current preparation affirmation
    var currentPreparationAffirmation: String {
        self.preparationAffirmations[self.displayState.currentAffirmationIndex % self.preparationAffirmations.count]
    }

    // MARK: - Action Dispatch

    /// Dispatches an action to the reducer and executes resulting effects
    func dispatch(_ action: TimerAction) {
        Logger.viewModel.debug("Dispatching action: \(String(describing: action))")

        let (newState, effects) = TimerReducer.reduce(
            state: self.displayState,
            action: action,
            settings: self.settings
        )

        self.displayState = newState
        self.executeEffects(effects)
    }

    // MARK: - Legacy Public Methods (For backward compatibility)

    /// Starts the timer with selected duration
    func startTimer() {
        self.dispatch(.startPressed)
    }

    /// Pauses the running timer
    func pauseTimer() {
        self.dispatch(.pausePressed)
    }

    /// Resumes the paused timer
    func resumeTimer() {
        self.dispatch(.resumePressed)
    }

    /// Resets the timer to initial state
    func resetTimer() {
        self.dispatch(.resetPressed)
    }

    /// Saves settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(self.settings.intervalGongsEnabled, forKey: MeditationSettings.Keys.intervalGongsEnabled)
        defaults.set(self.settings.intervalMinutes, forKey: MeditationSettings.Keys.intervalMinutes)
        defaults.set(self.settings.backgroundSoundId, forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.set(self.settings.durationMinutes, forKey: MeditationSettings.Keys.durationMinutes)
        defaults.set(self.settings.preparationTimeEnabled, forKey: MeditationSettings.Keys.preparationTimeEnabled)
        defaults.set(self.settings.preparationTimeSeconds, forKey: MeditationSettings.Keys.preparationTimeSeconds)
        defaults.set(self.settings.startGongSoundId, forKey: MeditationSettings.Keys.startGongSoundId)
        Logger.viewModel.info("Saved settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundSoundId": self.settings.backgroundSoundId,
            "durationMinutes": self.settings.durationMinutes,
            "preparationEnabled": self.settings.preparationTimeEnabled,
            "preparationSeconds": self.settings.preparationTimeSeconds,
            "startGongSoundId": self.settings.startGongSoundId
        ])
    }

    // MARK: Private

    private let timerService: TimerServiceProtocol
    private let audioService: AudioServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var previousState: TimerState = .idle

    /// Affirmations for running state
    private var runningAffirmations: [String] {
        [
            NSLocalizedString("affirmation.running.1", comment: ""),
            NSLocalizedString("affirmation.running.2", comment: ""),
            NSLocalizedString("affirmation.running.3", comment: ""),
            NSLocalizedString("affirmation.running.4", comment: ""),
            NSLocalizedString("affirmation.running.5", comment: "")
        ]
    }

    /// Affirmations for preparation state
    private var preparationAffirmations: [String] {
        [
            NSLocalizedString("affirmation.preparation.1", comment: ""),
            NSLocalizedString("affirmation.preparation.2", comment: ""),
            NSLocalizedString("affirmation.preparation.3", comment: ""),
            NSLocalizedString("affirmation.preparation.4", comment: "")
        ]
    }

    // MARK: - Effect Execution

    private func executeEffects(_ effects: [TimerEffect]) {
        for effect in effects {
            self.executeEffect(effect)
        }
    }

    private func executeEffect(_ effect: TimerEffect) {
        Logger.viewModel.debug("Executing effect: \(String(describing: effect))")

        if self.executeAudioEffect(effect) {
            return
        }
        if self.executeTimerEffect(effect) {
            return
        }
        if self.executeSettingsEffect(effect) {
            return
        }
    }

    private func executeAudioEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
        case .configureAudioSession:
            self.executeConfigureAudioSession()
        case let .startBackgroundAudio(soundId):
            self.executeStartBackgroundAudio(soundId: soundId)
        case .stopBackgroundAudio:
            self.audioService.stopBackgroundAudio()
        case .pauseBackgroundAudio:
            self.audioService.pauseBackgroundAudio()
        case .resumeBackgroundAudio:
            self.audioService.resumeBackgroundAudio()
        case .playStartGong:
            self.executePlayStartGong()
        case .playIntervalGong:
            self.executePlayIntervalGong()
        case .playCompletionSound:
            self.executePlayCompletionSound()
        default:
            return false
        }
        return true
    }

    private func executeTimerEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
        case let .startTimer(durationMinutes):
            self.executeStartTimer(durationMinutes: durationMinutes)
        case .pauseTimer:
            self.timerService.pause()
        case .resumeTimer:
            self.timerService.resume()
        case .resetTimer:
            self.timerService.reset()
        default:
            return false
        }
        return true
    }

    private func executeSettingsEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
        case let .saveSettings(settings):
            self.executeSaveSettings(settings)
        default:
            return false
        }
        return true
    }

    // MARK: - Audio Effect Handlers

    private func executeConfigureAudioSession() {
        do {
            try self.audioService.configureAudioSession()
            Logger.viewModel.info("Audio session configured for timer")
        } catch {
            Logger.viewModel.error("Failed to configure audio session", error: error)
            self.errorMessage = "Failed to prepare audio: \(error.localizedDescription)"
        }
    }

    private func executeStartBackgroundAudio(soundId: String) {
        do {
            try self.audioService.startBackgroundAudio(soundId: soundId)
        } catch {
            Logger.viewModel.error("Failed to start background audio", error: error)
            self.errorMessage = "Failed to start background audio: \(error.localizedDescription)"
        }
    }

    private func executePlayStartGong() {
        do {
            try self.audioService.playStartGong(soundId: self.settings.startGongSoundId)
        } catch {
            Logger.viewModel.error("Failed to play start gong", error: error)
            self.errorMessage = "Failed to play start sound: \(error.localizedDescription)"
        }
    }

    private func executePlayIntervalGong() {
        do {
            try self.audioService.playIntervalGong()
            // Mark gong played on timer to enable detection of next interval
            self.timerService.markIntervalGongPlayed()
            // Reset the UI flag to allow next interval detection
            self.dispatch(.intervalGongPlayed)
        } catch {
            Logger.viewModel.error("Failed to play interval gong", error: error)
            self.errorMessage = "Failed to play interval sound: \(error.localizedDescription)"
        }
    }

    private func executePlayCompletionSound() {
        do {
            try self.audioService.playCompletionSound(soundId: self.settings.startGongSoundId)
        } catch {
            Logger.viewModel.error("Failed to play completion sound", error: error)
            self.errorMessage = "Failed to play sound: \(error.localizedDescription)"
        }
    }

    // MARK: - Timer Effect Handlers

    private func executeStartTimer(durationMinutes: Int) {
        self.settings.durationMinutes = durationMinutes
        // Use preparation time from settings, or 0 if disabled
        let preparationTime = self.settings.preparationTimeEnabled
            ? self.settings.preparationTimeSeconds
            : 0
        self.timerService.start(durationMinutes: durationMinutes, preparationTimeSeconds: preparationTime)
    }

    private func executeSaveSettings(_ settings: MeditationSettings) {
        self.settings = settings
        self.saveSettings()
    }

    // MARK: - Bindings

    private func setupBindings() {
        self.timerService.timerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timer in
                self?.handleTimerUpdate(timer)
            }
            .store(in: &self.cancellables)
    }

    private func handleTimerUpdate(_ timer: MeditationTimer) {
        // Dispatch tick action with timer values
        self.dispatch(.tick(
            remainingSeconds: timer.remainingSeconds,
            totalSeconds: timer.totalSeconds,
            remainingPreparationSeconds: timer.remainingPreparationSeconds,
            progress: timer.progress,
            state: timer.state
        ))

        // Detect state transitions for effects
        self.handleStateTransition(from: self.previousState, to: timer.state, timer: timer)
        self.previousState = timer.state
    }

    private func handleStateTransition(
        from oldState: TimerState,
        to newState: TimerState,
        timer: MeditationTimer
    ) {
        // Transition to Running (from Preparation OR Idle): Play start gong
        // - With preparation: idle → preparation → running
        // - Without preparation: idle → running (direct)
        if newState == .running, oldState == .preparation || oldState == .idle {
            Logger.viewModel.info("Meditation starting, dispatching preparationFinished")
            self.dispatch(.preparationFinished)
            // Don't return - interval gong check must still run (for test scenarios
            // simulating elapsed time; in production elapsed=0 so no gong triggers)
        }

        // → Completed: Dispatch timerCompleted
        if newState == .completed, oldState != .completed {
            Logger.viewModel.info("Timer completed, dispatching timerCompleted")
            self.dispatch(.timerCompleted)
            return // No interval gongs after completion
        }

        // Check for interval gongs while running
        if newState == .running, self.settings.intervalGongsEnabled {
            if timer.shouldPlayIntervalGong(intervalMinutes: self.settings.intervalMinutes) {
                Logger.viewModel.info("Interval gong triggered", metadata: [
                    "interval": self.settings.intervalMinutes,
                    "remaining": timer.remainingSeconds
                ])
                self.dispatch(.intervalGongTriggered)
            }
        }
    }

    // MARK: - Settings Management

    private func loadSettings() {
        let defaults = UserDefaults.standard
        let backgroundSoundId = self.loadBackgroundSoundId(from: defaults)
        let durationMinutes = defaults.object(forKey: MeditationSettings.Keys.durationMinutes) != nil
            ? defaults.integer(forKey: MeditationSettings.Keys.durationMinutes) : 10
        let preparationTimeEnabled = defaults.object(forKey: MeditationSettings.Keys.preparationTimeEnabled) != nil
            ? defaults.bool(forKey: MeditationSettings.Keys.preparationTimeEnabled) : true
        let preparationTimeSeconds = defaults.object(forKey: MeditationSettings.Keys.preparationTimeSeconds) != nil
            ? defaults.integer(forKey: MeditationSettings.Keys.preparationTimeSeconds) : 15
        let startGongSoundId = defaults.string(forKey: MeditationSettings.Keys.startGongSoundId)
            ?? GongSound.defaultSoundId

        self.settings = MeditationSettings(
            intervalGongsEnabled: defaults.bool(forKey: MeditationSettings.Keys.intervalGongsEnabled),
            intervalMinutes: defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes) == 0
                ? 5 : defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes),
            backgroundSoundId: backgroundSoundId,
            durationMinutes: durationMinutes,
            preparationTimeEnabled: preparationTimeEnabled,
            preparationTimeSeconds: preparationTimeSeconds,
            startGongSoundId: startGongSoundId
        )
        self.logLoadedSettings()
    }

    private func loadBackgroundSoundId(from defaults: UserDefaults) -> String {
        if let soundId = defaults.string(forKey: MeditationSettings.Keys.backgroundSoundId),
           !soundId.isEmpty {
            return soundId
        }
        // Legacy migration
        if let legacyMode = defaults.string(forKey: MeditationSettings.Keys.legacyBackgroundAudioMode) {
            let migratedId = MeditationSettings.migrateLegacyMode(legacyMode)
            defaults.set(migratedId, forKey: MeditationSettings.Keys.backgroundSoundId)
            Logger.viewModel.info("Migrated legacy settings", metadata: [
                "legacyMode": legacyMode,
                "newSoundId": migratedId
            ])
            return migratedId
        }
        return "silent"
    }

    private func logLoadedSettings() {
        Logger.viewModel.info("Loaded settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundSoundId": self.settings.backgroundSoundId,
            "durationMinutes": self.settings.durationMinutes,
            "preparationEnabled": self.settings.preparationTimeEnabled,
            "preparationSeconds": self.settings.preparationTimeSeconds,
            "startGongSoundId": self.settings.startGongSoundId
        ])
    }
}

// MARK: - Preview Support

extension TimerViewModel {
    /// Creates a view model with mocked services for previews
    static func preview(state: TimerState = .idle) -> TimerViewModel {
        let viewModel = TimerViewModel()

        // Directly modify displayState for preview
        var newState = viewModel.displayState
        newState.timerState = state

        switch state {
        case .idle:
            newState.remainingSeconds = 0
            newState.totalSeconds = 600
        case .preparation:
            newState.remainingSeconds = 600
            newState.totalSeconds = 600
            newState.remainingPreparationSeconds = 10
        case .running,
             .paused:
            newState.remainingSeconds = 300
            newState.totalSeconds = 600
            newState.progress = 0.5
        case .completed:
            newState.remainingSeconds = 0
            newState.totalSeconds = 600
            newState.progress = 1.0
        }

        viewModel.displayState = newState
        return viewModel
    }
}
