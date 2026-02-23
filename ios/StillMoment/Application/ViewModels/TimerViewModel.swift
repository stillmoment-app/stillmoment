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
        settingsRepository: TimerSettingsRepository = UserDefaultsTimerSettingsRepository(),
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository(),
        praxisRepository: PraxisRepository = UserDefaultsPraxisRepository(),
        customAudioRepository: CustomAudioRepositoryProtocol = CustomAudioRepository()
    ) {
        self.timerService = timerService
        self.audioService = audioService
        self.settingsRepository = settingsRepository
        self.soundRepository = soundRepository
        self.praxisRepository = praxisRepository
        self.customAudioRepository = customAudioRepository

        self.settings = settingsRepository.load()
        // Initialize selected minutes from saved duration (clamped to minimum for introduction)
        self.selectedMinutes = MeditationSettings.validateDuration(
            self.settings.durationMinutes,
            introductionId: self.settings.introductionId
        )
        self.activePraxisName = Self.resolveActivePraxisName(from: praxisRepository)
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

    /// Name of the currently active Praxis (shown in pill button)
    @Published var activePraxisName: String = ""

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

    /// Minimum duration in minutes based on current introduction setting
    var minimumDurationMinutes: Int {
        MeditationSettings.minimumDuration(for: self.settings.introductionId)
    }

    /// Whether the timer is actively running
    var isRunning: Bool {
        self.timer?.isRunning ?? false
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

    /// Display name for the active Praxis, with fallback for empty name
    var displayPraxisName: String {
        self.activePraxisName.isEmpty
            ? NSLocalizedString("praxis.default.name", comment: "")
            : self.activePraxisName
    }

    /// Applies a Praxis configuration: updates settings, selectedMinutes, and active praxis name
    func applyPraxis(_ praxis: Praxis) {
        let settings = praxis.toMeditationSettings()
        self.settings = settings
        self.selectedMinutes = MeditationSettings.validateDuration(
            praxis.durationMinutes,
            introductionId: praxis.introductionId
        )
        self.settingsRepository.save(settings)
        self.activePraxisName = praxis.name
        Logger.viewModel.info("Applied praxis", metadata: ["name": praxis.name])
    }

    // MARK: Private

    private let timerService: TimerServiceProtocol
    let audioService: AudioServiceProtocol
    private let settingsRepository: TimerSettingsRepository
    let soundRepository: BackgroundSoundRepositoryProtocol
    private let praxisRepository: PraxisRepository
    private let customAudioRepository: CustomAudioRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Selected minutes before introduction auto-clamped, restored when introduction is disabled.
    private var minutesBeforeIntroduction: Int?

    private static func resolveActivePraxisName(from repository: PraxisRepository) -> String {
        let all = repository.loadAll()
        if let id = repository.activePraxisId,
           let praxis = all.first(where: { $0.id == id }) {
            return praxis.name
        }
        return all.first?.name ?? ""
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
        if self.executeSettingsEffect(effect) {
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
        case .transitionToCompleted:
            self.timer = self.timer?.withState(.completed)
        case .clearTimer:
            self.timer = nil
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
        self.$settings
            .map(\.introductionId)
            .removeDuplicates()
            .sink { [weak self] introductionId in
                guard let self
                else { return }
                let minimum = MeditationSettings.minimumDuration(for: introductionId)
                if introductionId != nil, self.selectedMinutes < minimum {
                    self.minutesBeforeIntroduction = self.selectedMinutes
                    self.selectedMinutes = minimum
                } else if introductionId == nil, let restored = self.minutesBeforeIntroduction {
                    self.selectedMinutes = restored
                    self.minutesBeforeIntroduction = nil
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
        // Update timer directly — no .tick dispatch needed
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

    func executePlayIntroduction(introductionId: String) {
        // Try built-in introduction first
        if let filename = Introduction.audioFilenameForCurrentLanguage(introductionId) {
            do {
                try self.audioService.playIntroduction(filename: filename)
                Logger.viewModel.info(
                    "Introduction audio started",
                    metadata: ["introductionId": introductionId]
                )
            } catch {
                Logger.viewModel.error("Failed to play introduction audio", error: error)
                self.errorMessage = "Failed to play introduction: \(error.localizedDescription)"
            }
            return
        }

        // Try custom attunement (UUID-based ID)
        if let uuid = UUID(uuidString: introductionId),
           let customFile = self.customAudioRepository.findFile(byId: uuid),
           let fileURL = self.customAudioRepository.fileURL(for: customFile) {
            do {
                try self.audioService.playIntroduction(filename: fileURL.path)
                Logger.viewModel.info(
                    "Custom attunement started",
                    metadata: ["id": introductionId]
                )
            } catch {
                Logger.viewModel.error("Failed to play custom attunement", error: error)
                self.errorMessage = "Failed to play introduction: \(error.localizedDescription)"
            }
            return
        }

        Logger.viewModel.error(
            "Introduction audio not available",
            metadata: [
                "introductionId": introductionId,
                "language": Introduction.currentLanguage
            ]
        )
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

    func executeSaveSettings(_ settings: MeditationSettings) {
        self.settings = settings
        self.settingsRepository.save(settings)
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
