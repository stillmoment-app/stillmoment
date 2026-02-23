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

    /// The complete display state managed by the reducer.
    /// Internal setter for cross-file extension access (TimerViewModel+Preview).
    @Published var displayState: TimerDisplayState = .initial

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
    let audioService: AudioServiceProtocol
    private let settingsRepository: TimerSettingsRepository
    let soundRepository: BackgroundSoundRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Selected minutes before introduction auto-clamped, restored when introduction is disabled.
    private var minutesBeforeIntroduction: Int?

    // MARK: - Effect Execution

    private func executeEffects(_ effects: [TimerEffect]) {
        for effect in effects {
            self.executeEffect(effect)
        }
    }

    private func executeEffect(_ effect: TimerEffect) {
        Logger.viewModel.debug("Executing effect: \(String(describing: effect))")

        if self.executeAudioSessionEffect(effect) {
            return
        }
        if self.executeAudioPlaybackEffect(effect) {
            return
        }
        if self.executeTimerEffect(effect) {
            return
        }
        if self.executeSettingsEffect(effect) {
            return
        }
    }

    private func executeAudioSessionEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
        case .configureAudioSession:
            self.executeConfigureAudioSession()
        case .activateTimerSession:
            self.executeActivateTimerSession()
        case .deactivateTimerSession:
            self.audioService.deactivateTimerSession()
        default:
            return false
        }
        return true
    }

    private func executeAudioPlaybackEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
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
        case .beginIntroductionPhase:
            self.timerService.beginIntroductionPhase()
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

    private func executeActivateTimerSession() {
        do {
            try self.audioService.activateTimerSession()
            Logger.viewModel.info("Timer session activated (audio session + keep-alive)")
        } catch {
            Logger.viewModel.error("Failed to activate timer session", error: error)
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

        // Build interval settings from current meditation settings (nil when disabled)
        let intervalSettings: IntervalSettings? = self.settings.intervalGongsEnabled
            ? IntervalSettings(
                intervalMinutes: self.settings.intervalMinutes,
                mode: self.settings.intervalMode
            )
            : nil

        self.timerService.start(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: preparationTime,
            intervalSettings: intervalSettings
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
            .sink { [weak self] timer, events in
                self?.handleTimerUpdate(timer, events: events)
            }
            .store(in: &self.cancellables)

        self.audioService.gongCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleGongCompletion()
            }
            .store(in: &self.cancellables)

        self.audioService.introductionCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.dispatch(.introductionFinished)
            }
            .store(in: &self.cancellables)

        // Enforce minimum duration when introduction changes, restore when disabled.
        // Updates displayState directly (not via reducer) because @Published willSet
        // means self.settings is still stale when the sink runs.
        self.$settings
            .map(\.introductionId)
            .removeDuplicates()
            .sink { [weak self] introductionId in
                guard let self
                else { return }
                let minimum = MeditationSettings.minimumDuration(for: introductionId)
                if introductionId != nil, self.displayState.selectedMinutes < minimum {
                    self.minutesBeforeIntroduction = self.displayState.selectedMinutes
                    self.displayState.selectedMinutes = minimum
                } else if introductionId == nil, let restored = self.minutesBeforeIntroduction {
                    self.displayState.selectedMinutes = restored
                    self.minutesBeforeIntroduction = nil
                }
            }
            .store(in: &self.cancellables)
    }

    /// Routes gong completion audio callbacks to the appropriate action based on current state
    private func handleGongCompletion() {
        switch self.displayState.timerState {
        case .startGong:
            self.dispatch(.startGongFinished)
        case .endGong:
            self.dispatch(.endGongFinished)
        case .running:
            break // Interval gong completed — no state transition needed
        default:
            Logger.viewModel.debug(
                "Gong completion received in unexpected state",
                metadata: ["state": String(describing: self.displayState.timerState)]
            )
        }
    }

    private func handleTimerUpdate(_ timer: MeditationTimer, events: [TimerEvent]) {
        // Dispatch tick action with timer values
        self.dispatch(.tick(
            remainingSeconds: timer.remainingSeconds,
            totalSeconds: timer.totalSeconds,
            remainingPreparationSeconds: timer.remainingPreparationSeconds,
            progress: timer.progress,
            state: timer.state
        ))

        // Process domain events emitted by tick()
        self.processTimerEvents(events)
    }

    /// Processes domain events from `MeditationTimer.tick()` and dispatches corresponding actions
    private func processTimerEvents(_ events: [TimerEvent]) {
        for event in events {
            switch event {
            case .preparationCompleted:
                Logger.viewModel.info("Meditation starting, dispatching preparationFinished")
                self.dispatch(.preparationFinished)

            case .meditationCompleted:
                Logger.viewModel.info("Timer reached zero, dispatching timerCompleted for endGong phase")
                self.dispatch(.timerCompleted)

            case .intervalGongDue:
                Logger.viewModel.info("Interval gong triggered via domain event")
                self.dispatch(.intervalGongTriggered)
            }
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

// Audio Preview and SwiftUI Preview support: see TimerViewModel+Preview.swift
// (access level widened for cross-file extension use)
