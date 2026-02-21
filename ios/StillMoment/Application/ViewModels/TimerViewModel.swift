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
        audioService: AudioServiceProtocol = AudioService(),
        settingsRepository: TimerSettingsRepository = UserDefaultsTimerSettingsRepository(),
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository()
    ) {
        self.timerService = timerService
        self.audioService = audioService
        self.settingsRepository = settingsRepository
        self.soundRepository = soundRepository

        self.settings = settingsRepository.load()
        // Initialize display state with saved duration (clamped to minimum for introduction)
        self.displayState = TimerDisplayState.withDuration(
            minutes: self.settings.durationMinutes,
            introductionId: self.settings.introductionId
        )
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
    var timerState: TimerState {
        self.displayState.timerState
    }

    /// Selected duration in minutes
    var selectedMinutes: Int {
        get { self.displayState.selectedMinutes }
        set { self.dispatch(.selectDuration(minutes: newValue)) }
    }

    /// Remaining time in seconds
    var remainingSeconds: Int {
        self.displayState.remainingSeconds
    }

    /// Total duration in seconds
    var totalSeconds: Int {
        self.displayState.totalSeconds
    }

    /// Progress value (0.0 - 1.0)
    var progress: Double {
        self.displayState.progress
    }

    /// Remaining preparation seconds
    var remainingPreparationSeconds: Int {
        self.displayState.remainingPreparationSeconds
    }

    /// Current affirmation index
    var currentAffirmationIndex: Int {
        self.displayState.currentAffirmationIndex
    }

    /// Whether currently in preparation phase
    var isPreparation: Bool {
        self.displayState.isPreparation
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        self.displayState.canStart
    }

    /// Minimum duration in minutes based on current introduction setting
    var minimumDurationMinutes: Int {
        MeditationSettings.minimumDuration(for: self.settings.introductionId)
    }

    /// Whether the timer is actively running
    var isRunning: Bool {
        self.displayState.isRunning
    }

    /// Formatted time string
    var formattedTime: String {
        self.displayState.formattedTime
    }

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

    // MARK: - Public Methods

    /// Starts the timer with selected duration
    func startTimer() {
        self.dispatch(.startPressed)
    }

    /// Resets the timer to initial state
    func resetTimer() {
        self.dispatch(.resetPressed)
    }

    // MARK: Private

    private let timerService: TimerServiceProtocol
    private let audioService: AudioServiceProtocol
    private let settingsRepository: TimerSettingsRepository
    private let soundRepository: BackgroundSoundRepositoryProtocol
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
        case let .startBackgroundAudio(soundId, volume):
            self.executeStartBackgroundAudio(soundId: soundId, volume: volume)
        case .stopBackgroundAudio:
            self.audioService.stopBackgroundAudio()
        case .playStartGong:
            self.executePlayStartGong()
        case let .playIntroduction(introductionId):
            self.executePlayIntroduction(introductionId: introductionId)
        case .stopIntroduction:
            self.audioService.stopIntroduction()
        case let .playIntervalGong(soundId, volume):
            self.executePlayIntervalGong(soundId: soundId, volume: volume)
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
        case .resetTimer:
            self.timerService.reset()
        case .endIntroductionPhase:
            self.timerService.endIntroductionPhase()
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

    private func executeStartBackgroundAudio(soundId: String, volume: Float) {
        do {
            try self.audioService.startBackgroundAudio(soundId: soundId, volume: volume)
        } catch {
            Logger.viewModel.error("Failed to start background audio", error: error)
            self.errorMessage = "Failed to start background audio: \(error.localizedDescription)"
        }
    }

    private func executePlayStartGong() {
        do {
            try self.audioService.playStartGong(
                soundId: self.settings.startGongSoundId,
                volume: self.settings.gongVolume
            )
        } catch {
            Logger.viewModel.error("Failed to play start gong", error: error)
            self.errorMessage = "Failed to play start sound: \(error.localizedDescription)"
        }
    }

    private func executePlayIntroduction(introductionId: String) {
        guard let filename = Introduction.audioFilenameForCurrentLanguage(introductionId) else {
            Logger.viewModel.error(
                "Introduction audio not available",
                metadata: ["introductionId": introductionId, "language": Introduction.currentLanguage]
            )
            return
        }

        do {
            try self.audioService.playIntroduction(filename: filename)
            Logger.viewModel.info("Introduction audio started", metadata: ["introductionId": introductionId])
        } catch {
            Logger.viewModel.error("Failed to play introduction audio", error: error)
            self.errorMessage = "Failed to play introduction: \(error.localizedDescription)"
        }
    }

    private func executePlayIntervalGong(soundId: String, volume: Float) {
        do {
            try self.audioService.playIntervalGong(soundId: soundId, volume: volume)
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
            try self.audioService.playCompletionSound(
                soundId: self.settings.startGongSoundId,
                volume: self.settings.gongVolume
            )
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

        self.timerService.start(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: preparationTime
        )
    }

    private func executeSaveSettings(_ settings: MeditationSettings) {
        self.settings = settings
        self.settingsRepository.save(settings)
    }

    // MARK: - Bindings

    private func setupBindings() {
        self.timerService.timerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timer in
                self?.handleTimerUpdate(timer)
            }
            .store(in: &self.cancellables)

        self.audioService.gongCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.dispatch(.startGongFinished)
            }
            .store(in: &self.cancellables)

        self.audioService.introductionCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.dispatch(.introductionFinished)
            }
            .store(in: &self.cancellables)

        // Enforce minimum duration when introduction changes
        self.$settings
            .map { MeditationSettings.minimumDuration(for: $0.introductionId) }
            .removeDuplicates()
            .sink { [weak self] minimum in
                guard let self, self.displayState.selectedMinutes < minimum else {
                    return
                }
                self.dispatch(.selectDuration(minutes: minimum))
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
        self.handlePhaseTransitions(from: oldState, to: newState)
        self.checkIntervalGongs(state: newState, timer: timer)
    }

    /// Dispatches actions for phase transitions in the meditation lifecycle.
    /// State machine: idle → preparation → startGong → [introduction →] running → completed
    private func handlePhaseTransitions(from oldState: TimerState, to newState: TimerState) {
        // Preparation/idle → startGong: play start gong
        if oldState == .preparation || oldState == .idle,
           newState == .startGong {
            Logger.viewModel.info("Meditation starting, dispatching preparationFinished")
            self.dispatch(.preparationFinished)
        }

        // Timer completed (any active state → completed)
        if oldState != .completed, newState == .completed {
            Logger.viewModel.info("Timer completed, dispatching timerCompleted")
            self.dispatch(.timerCompleted)
        }
    }

    /// Checks if an interval gong should be played (only during silent meditation phase)
    private func checkIntervalGongs(state: TimerState, timer: MeditationTimer) {
        guard state == .running, self.settings.intervalGongsEnabled else {
            return
        }

        if timer.shouldPlayIntervalGong(
            intervalMinutes: self.settings.intervalMinutes,
            mode: self.settings.intervalMode
        ) {
            Logger.viewModel.info("Interval gong triggered", metadata: [
                "interval": self.settings.intervalMinutes,
                "mode": self.settings.intervalMode.rawValue,
                "remaining": timer.remainingSeconds
            ])
            self.dispatch(.intervalGongTriggered)
        }
    }
}

// MARK: - Settings Persistence

extension TimerViewModel {
    /// Saves current settings via the repository
    func saveSettings() {
        self.settingsRepository.save(self.settings)
    }
}

// MARK: - Audio Preview (for Settings UI)

extension TimerViewModel {
    /// All available background sounds from the repository
    var availableBackgroundSounds: [BackgroundSound] {
        self.soundRepository.availableSounds
    }

    /// Introductions available for the current device language
    var availableIntroductions: [Introduction] {
        Introduction.availableForCurrentLanguage()
    }

    /// Plays a gong sound preview when user changes gong selection in settings
    func playGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play gong preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Plays an interval gong preview when user changes interval sound or adjusts volume in settings
    func playIntervalGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play interval gong preview", error: error)
        }
    }

    /// Plays a background sound preview when user changes background sound in settings
    func playBackgroundPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playBackgroundPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play background preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Stops all active audio previews (called on settings dismiss)
    func stopAllPreviews() {
        self.audioService.stopGongPreview()
        self.audioService.stopBackgroundPreview()
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
        case .startGong:
            newState.remainingSeconds = 597
            newState.totalSeconds = 600
            newState.progress = 0.005
        case .introduction:
            newState.remainingSeconds = 505
            newState.totalSeconds = 600
            newState.progress = 0.158
        case .running:
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
