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
/// 2. Reducer produces effects (pure function)
/// 3. Effects are executed by the effect handler
/// 4. MeditationTimer updates trigger view updates directly
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        timerService: TimerServiceProtocol = TimerService(),
        audioService: AudioServiceProtocol = AudioService(),
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository(),
        praxisRepository: PraxisRepository = UserDefaultsPraxisRepository(),
        customAudioRepository: CustomAudioRepositoryProtocol = CustomAudioRepository(),
        attunementResolver: AttunementResolverProtocol? = nil,
        soundscapeResolver: SoundscapeResolverProtocol? = nil
    ) {
        self.timerService = timerService
        self.audioService = audioService
        self.soundRepository = soundRepository
        self.praxisRepository = praxisRepository
        self.customAudioRepository = customAudioRepository
        self.attunementResolver = attunementResolver ?? AttunementResolver(
            customAudioRepository: customAudioRepository
        )
        self.soundscapeResolver = soundscapeResolver ?? SoundscapeResolver(
            soundRepository: soundRepository,
            customAudioRepository: customAudioRepository
        )

        // Load current Praxis and apply its configuration
        let praxis = praxisRepository.load()
        self.currentPraxis = praxis
        let customAttunementDuration = self.resolveAttunementDurationSeconds(attunementId: praxis.attunementId)
        self.settings = praxis.toMeditationSettings(customAttunementDurationSeconds: customAttunementDuration)
        self.selectedMinutes = self.settings.durationMinutes
        self.setupBindings()
    }

    // MARK: Internal

    // MARK: - Published State

    /// The meditation timer (nil when idle — no dummy object)
    @Published var timer: MeditationTimer?

    /// Selected duration in minutes (1-60), managed directly by the ViewModel
    @Published var selectedMinutes: Int = 10

    /// Meditation settings (interval gongs, background sound, etc.)
    @Published var settings: MeditationSettings = .default

    /// Error message if any operation fails
    @Published var errorMessage: String?

    /// The current Praxis configuration (single config, loaded from repository on init)
    @Published var currentPraxis: Praxis = .default

    /// Current affirmation index (rotates between sessions)
    var currentAffirmationIndex: Int = 0

    // MARK: - Computed Properties (Forwarded from MeditationTimer)

    /// Current timer state
    var timerState: TimerState {
        self.timer?.state ?? .idle
    }

    /// Remaining time in seconds
    var remainingSeconds: Int {
        self.timer?.remainingSeconds ?? 0
    }

    /// Total duration in seconds
    var totalSeconds: Int {
        self.timer?.totalSeconds ?? 0
    }

    /// Progress value (0.0 - 1.0)
    var progress: Double {
        self.timer?.progress ?? 0.0
    }

    /// Remaining preparation seconds
    var remainingPreparationSeconds: Int {
        self.timer?.remainingPreparationSeconds ?? 0
    }

    /// Whether currently in preparation phase
    var isPreparation: Bool {
        self.timer?.isPreparation ?? false
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        self.timer == nil && self.selectedMinutes > 0
    }

    /// Minimum duration in minutes based on current attunement setting
    var minimumDurationMinutes: Int {
        self.settings.minimumDurationMinutes
    }

    /// Whether the timer is actively running
    var isRunning: Bool {
        self.timer?.isRunning ?? false
    }

    /// Whether Zen Mode is active: tab bar and distracting UI should be hidden during meditation
    /// Includes the completion screen — tab bar stays hidden until user taps "Back"
    var isZenMode: Bool {
        self.timerState != .idle
    }

    /// Formatted time string
    var formattedTime: String {
        self.timer?.formattedTime ?? "00:00"
    }

    // MARK: - Action Dispatch

    /// Dispatches an action to the reducer and executes resulting effects
    func dispatch(_ action: TimerAction) {
        Logger.viewModel.debug("Dispatching action: \(String(describing: action))")

        // Affirmation rotation (UI-only state, not part of domain)
        if case .startPressed = action {
            self.currentAffirmationIndex = (self.currentAffirmationIndex + 1) % 5
        }

        let effects = TimerReducer.reduce(
            action: action,
            timerState: self.timer?.state ?? .idle,
            selectedMinutes: self.selectedMinutes,
            settings: self.settings,
            attunementResolver: self.attunementResolver
        )

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

    /// Creates a configured PraxisEditorViewModel that saves back to this TimerViewModel.
    /// Uses the shared AudioService — no separate instance is created.
    func makePraxisEditorViewModel(praxis: Praxis) -> PraxisEditorViewModel {
        PraxisEditorViewModel(praxis: praxis, audioService: self.audioService) { [weak self] savedPraxis in
            self?.updateFromPraxis(savedPraxis)
        }
    }

    /// Applies a Praxis configuration: updates currentPraxis, settings, and selectedMinutes.
    /// Called by the PraxisEditorView's onSaved callback.
    func updateFromPraxis(_ praxis: Praxis) {
        self.currentPraxis = praxis
        let customAttunementDuration = self.resolveAttunementDurationSeconds(attunementId: praxis.attunementId)
        let settings = praxis.toMeditationSettings(customAttunementDurationSeconds: customAttunementDuration)
        self.settings = settings
        self.selectedMinutes = settings.durationMinutes
        Logger.viewModel.info("Updated from praxis")
    }

    // MARK: Private

    private let timerService: TimerServiceProtocol
    let audioService: AudioServiceProtocol
    let soundRepository: BackgroundSoundRepositoryProtocol
    private let praxisRepository: PraxisRepository
    let customAudioRepository: CustomAudioRepositoryProtocol
    let attunementResolver: AttunementResolverProtocol
    let soundscapeResolver: SoundscapeResolverProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Selected minutes before attunement auto-clamped, restored when attunement is disabled.
    private var minutesBeforeAttunement: Int?

    /// Returns the attunement duration in seconds via the resolver, or nil if not found.
    func resolveAttunementDurationSeconds(attunementId: String? = nil) -> Int? {
        let resolvedId = attunementId ?? self.settings.attunementId
        guard let resolvedId else {
            return nil
        }
        return self.attunementResolver.resolve(id: resolvedId)?.durationSeconds
    }

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
    }

    private func executeAudioSessionEffect(_ effect: TimerEffect) -> Bool {
        switch effect {
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
        case let .playAttunement(attunementId):
            self.executePlayAttunement(attunementId: attunementId)
        case .stopAttunement:
            self.audioService.stopAttunement()
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
        case .beginAttunementPhase:
            self.timerService.beginAttunementPhase()
        case .endAttunementPhase:
            self.timerService.endAttunementPhase()
        case .beginRunningPhase:
            self.timerService.beginRunningPhase()
        case .transitionToCompleted:
            self.timer = self.timer?.withState(.completed)
        case .clearTimer:
            self.timer = nil
        default:
            return false
        }
        return true
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

        self.audioService.attunementCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.dispatch(.attunementFinished)
            }
            .store(in: &self.cancellables)

        // Enforce minimum duration when attunement changes, restore when disabled.
        // Note: Uses static method instead of settings.minimumDurationMinutes because
        // @Published fires in willSet — self.settings still has the old value here.
        self.$settings
            .map(\.attunementId)
            .removeDuplicates()
            .sink { [weak self] attunementId in
                guard let self
                else { return }
                let attunementDuration = self.resolveAttunementDurationSeconds(attunementId: attunementId)
                let minimum = MeditationSettings.minimumDuration(
                    for: attunementId,
                    attunementEnabled: self.settings.attunementEnabled,
                    attunementDurationSeconds: attunementDuration
                )
                if attunementId != nil, self.selectedMinutes < minimum {
                    self.minutesBeforeAttunement = self.selectedMinutes
                    self.selectedMinutes = minimum
                } else if attunementId == nil, let restored = self.minutesBeforeAttunement {
                    self.selectedMinutes = restored
                    self.minutesBeforeAttunement = nil
                }
            }
            .store(in: &self.cancellables)
    }

    /// Routes gong completion audio callbacks to the appropriate action based on current state
    private func handleGongCompletion() {
        switch self.timerState {
        case .startGong:
            self.dispatch(.startGongFinished)
        case .endGong:
            self.dispatch(.endGongFinished)
        case .running:
            break // Interval gong completed — no state transition needed
        default:
            Logger.viewModel.debug(
                "Gong completion received in unexpected state",
                metadata: ["state": String(describing: self.timerState)]
            )
        }
    }

    private func handleTimerUpdate(_ timer: MeditationTimer, events: [TimerEvent]) {
        // Ignore idle-state timers: TimerService.reset() publishes an idle timer asynchronously
        // via receive(on: DispatchQueue.main), which can arrive after .clearTimer already set
        // self.timer = nil, re-introducing the timer and hiding the Start button.
        guard timer.state != .idle else {
            return
        }

        self.timer = timer

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

// MARK: - Audio Effect Handlers

private extension TimerViewModel {
    func executeActivateTimerSession() {
        do {
            try self.audioService.activateTimerSession()
            Logger.viewModel.info("Timer session activated (audio session + keep-alive)")
        } catch {
            Logger.viewModel.error("Failed to activate timer session", error: error)
            self.errorMessage = "Failed to prepare audio: \(error.localizedDescription)"
        }
    }

    func executeStartBackgroundAudio(soundId: String, volume: Float) {
        do {
            try self.audioService.startBackgroundAudio(soundId: soundId, volume: volume)
        } catch {
            Logger.viewModel.error("Failed to start background audio", error: error)
            self.errorMessage = "Failed to start background audio: \(error.localizedDescription)"
        }
    }

    func executePlayStartGong() {
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

    func executePlayAttunement(attunementId: String) {
        do {
            let url = try self.attunementResolver.resolveAudioURL(id: attunementId)
            try self.audioService.playAttunement(filename: url.path)
            Logger.viewModel.info(
                "Attunement audio started",
                metadata: ["attunementId": attunementId]
            )
        } catch {
            Logger.viewModel.error("Failed to play attunement audio", error: error)
            self.errorMessage = "Failed to play attunement: \(error.localizedDescription)"
        }
    }

    func executePlayIntervalGong(soundId: String, volume: Float) {
        do {
            try self.audioService.playIntervalGong(soundId: soundId, volume: volume)
        } catch {
            Logger.viewModel.error("Failed to play interval gong", error: error)
            self.errorMessage = "Failed to play interval sound: \(error.localizedDescription)"
        }
    }

    func executePlayCompletionSound() {
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
}

// MARK: - Timer Effect Handlers

private extension TimerViewModel {
    func executeStartTimer(durationMinutes: Int) {
        self.settings.durationMinutes = durationMinutes
        // Persist the selected duration so the next launch restores it
        let updatedPraxis = self.currentPraxis.withDurationMinutes(durationMinutes)
        self.currentPraxis = updatedPraxis
        self.praxisRepository.save(updatedPraxis)
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
}

// Audio Preview and SwiftUI Preview support: see TimerViewModel+Preview.swift
// Configuration description labels: see TimerViewModel+ConfigurationDescription.swift
// (access level widened for cross-file extension use)
