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
        soundscapeResolver: SoundscapeResolverProtocol? = nil
    ) {
        self.timerService = timerService
        self.audioService = audioService
        self.soundRepository = soundRepository
        self.praxisRepository = praxisRepository
        self.customAudioRepository = customAudioRepository
        self.soundscapeResolver = soundscapeResolver ?? SoundscapeResolver(
            soundRepository: soundRepository,
            customAudioRepository: customAudioRepository
        )

        let praxis = praxisRepository.load()
        self.currentPraxis = praxis

        // sessionEditor is constructed with a placeholder onSaved because Swift
        // forbids `[weak self]` until every stored property is initialised.
        // The real callback is wired up below, once `self` is fully usable.
        self.sessionEditor = PraxisEditorViewModel(
            praxis: praxis,
            repository: praxisRepository,
            audioService: audioService,
            soundRepository: soundRepository,
            customAudioRepository: customAudioRepository
        ) { _ in }

        self.settings = praxis.toMeditationSettings()
        self.selectedMinutes = self.settings.durationMinutes

        self.setupBindings()

        self.sessionEditor.onSaved = { [weak self] saved in
            self?.updateFromPraxis(saved)
        }
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

    /// Editor view model used by the four setting detail views.
    ///
    /// Owned by the TimerViewModel (one instance per session) so the detail
    /// views can be reached without any lazy-init / race-condition gymnastics
    /// in the View layer. Live-save handles persistence; `onSaved` updates
    /// `currentPraxis` here on every change.
    let sessionEditor: PraxisEditorViewModel

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

    /// Visuelle Phase fuer den geteilten `BreathingCircleView`.
    ///
    /// - `.preRoll` waehrend der Vorbereitungs-Countdown laeuft.
    /// - `.playing` ansonsten — der Atemkreis sieht in StartGong, Running und
    ///   EndGong identisch aus (Bogen waechst, Atem laeuft).
    var phase: MeditationPhase {
        self.isPreparation ? .preRoll : .playing
    }

    /// Restzeit fuer das "NOCH … MIN"-Label im Atemkreis-Layout.
    ///
    /// Format `m:ss` (Player-Konvention, ohne Minuten-Padding) — verwendet
    /// zusammen mit `guided_meditations.player.remainingTime.format`.
    var formattedRemainingMinutes: String {
        let minutes = self.remainingSeconds / 60
        let seconds = self.remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        self.timer == nil && self.selectedMinutes > 0
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

    // MARK: - Action Dispatch

    /// Dispatches an action to the reducer and executes resulting effects
    func dispatch(_ action: TimerAction) {
        Logger.viewModel.debug("Dispatching action: \(String(describing: action))")

        let effects = TimerReducer.reduce(
            action: action,
            timerState: self.timer?.state ?? .idle,
            selectedMinutes: self.selectedMinutes,
            settings: self.settings
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

    /// Applies a Praxis configuration: updates currentPraxis, settings, and selectedMinutes.
    /// Called by `sessionEditor`'s onSaved callback after every live-save.
    func updateFromPraxis(_ praxis: Praxis) {
        self.currentPraxis = praxis
        let settings = praxis.toMeditationSettings()
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
    let soundscapeResolver: SoundscapeResolverProtocol
    private var cancellables = Set<AnyCancellable>()

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

        self.bindSelectedMinutesToEditor()
    }

    /// Keep the editor's durationMinutes in sync with the wheel picker.
    /// Without this, an editor live-save (e.g. flipping a toggle in a detail
    /// view) would persist the editor's stale durationMinutes and overwrite
    /// whatever the user dialed in on the idle screen.
    private func bindSelectedMinutesToEditor() {
        self.$selectedMinutes
            .removeDuplicates()
            .sink { [weak self] minutes in
                guard let self
                else { return }
                if self.sessionEditor.durationMinutes != minutes {
                    self.sessionEditor.durationMinutes = minutes
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
