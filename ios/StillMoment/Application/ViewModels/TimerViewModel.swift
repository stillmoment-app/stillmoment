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

    /// Countdown seconds
    var countdownSeconds: Int { self.displayState.countdownSeconds }

    /// Current affirmation index
    var currentAffirmationIndex: Int { self.displayState.currentAffirmationIndex }

    /// Whether currently in countdown phase
    var isCountdown: Bool { self.displayState.isCountdown }

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

    /// Get current countdown affirmation
    var currentCountdownAffirmation: String {
        self.countdownAffirmations[self.displayState.currentAffirmationIndex % self.countdownAffirmations.count]
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
        Logger.viewModel.info("Saved settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundSoundId": self.settings.backgroundSoundId,
            "durationMinutes": self.settings.durationMinutes
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

    /// Affirmations for countdown state
    private var countdownAffirmations: [String] {
        [
            NSLocalizedString("affirmation.countdown.1", comment: ""),
            NSLocalizedString("affirmation.countdown.2", comment: ""),
            NSLocalizedString("affirmation.countdown.3", comment: ""),
            NSLocalizedString("affirmation.countdown.4", comment: "")
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
            try self.audioService.playStartGong()
        } catch {
            Logger.viewModel.error("Failed to play start gong", error: error)
            self.errorMessage = "Failed to play start sound: \(error.localizedDescription)"
        }
    }

    private func executePlayIntervalGong() {
        do {
            try self.audioService.playIntervalGong()
        } catch {
            Logger.viewModel.error("Failed to play interval gong", error: error)
            self.errorMessage = "Failed to play interval sound: \(error.localizedDescription)"
        }
    }

    private func executePlayCompletionSound() {
        do {
            try self.audioService.playCompletionSound()
        } catch {
            Logger.viewModel.error("Failed to play completion sound", error: error)
            self.errorMessage = "Failed to play sound: \(error.localizedDescription)"
        }
    }

    // MARK: - Timer Effect Handlers

    private func executeStartTimer(durationMinutes: Int) {
        self.settings.durationMinutes = durationMinutes
        self.timerService.start(durationMinutes: durationMinutes)
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
            countdownSeconds: timer.countdownSeconds,
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
        // Countdown → Running: Dispatch countdownFinished
        if oldState == .countdown, newState == .running {
            Logger.viewModel.info("Countdown complete, dispatching countdownFinished")
            self.dispatch(.countdownFinished)
            return
        }

        // → Completed: Dispatch timerCompleted
        if newState == .completed, oldState != .completed {
            Logger.viewModel.info("Timer completed, dispatching timerCompleted")
            self.dispatch(.timerCompleted)
            return
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

        // Try to load backgroundSoundId, with legacy migration
        var backgroundSoundId = defaults.string(forKey: MeditationSettings.Keys.backgroundSoundId)

        if backgroundSoundId == nil || backgroundSoundId?.isEmpty == true {
            if let legacyMode = defaults.string(forKey: MeditationSettings.Keys.legacyBackgroundAudioMode) {
                backgroundSoundId = MeditationSettings.migrateLegacyMode(legacyMode)
                defaults.set(backgroundSoundId, forKey: MeditationSettings.Keys.backgroundSoundId)
                Logger.viewModel.info("Migrated legacy settings", metadata: [
                    "legacyMode": legacyMode,
                    "newSoundId": backgroundSoundId ?? "unknown"
                ])
            }
        }

        let durationMinutes: Int = if defaults.object(forKey: MeditationSettings.Keys.durationMinutes) != nil {
            defaults.integer(forKey: MeditationSettings.Keys.durationMinutes)
        } else {
            10
        }

        self.settings = MeditationSettings(
            intervalGongsEnabled: defaults.bool(forKey: MeditationSettings.Keys.intervalGongsEnabled),
            intervalMinutes: defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes) == 0
                ? 5 : defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes),
            backgroundSoundId: backgroundSoundId ?? "silent",
            durationMinutes: durationMinutes
        )
        Logger.viewModel.info("Loaded settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundSoundId": self.settings.backgroundSoundId,
            "durationMinutes": self.settings.durationMinutes
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
        case .countdown:
            newState.remainingSeconds = 600
            newState.totalSeconds = 600
            newState.countdownSeconds = 10
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
