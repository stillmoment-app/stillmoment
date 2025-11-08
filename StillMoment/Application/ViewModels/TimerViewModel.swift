//
//  TimerViewModel.swift
//  Still Moment
//
//  Application Layer - Timer ViewModel
//

import Combine
import Foundation
import OSLog

/// ViewModel managing timer state and user interactions
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        timerService: TimerServiceProtocol = TimerService(),
        audioService: AudioServiceProtocol = AudioService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.timerService = timerService
        self.audioService = audioService
        self.notificationService = notificationService

        self.loadSettings()
        self.setupBindings()
        // Don't configure audio on init - it will be configured on-demand when audio is needed
        // This saves energy in idle state
    }

    // MARK: Internal

    // MARK: - Published Properties

    /// Selected duration in minutes (1-60)
    @Published var selectedMinutes: Int = 10

    /// Current timer state
    @Published var timerState: TimerState = .idle

    /// Remaining time in seconds
    @Published var remainingSeconds: Int = 0

    /// Total duration in seconds
    @Published var totalSeconds: Int = 0

    /// Progress value (0.0 - 1.0)
    @Published var progress: Double = 0.0

    /// Error message if any operation fails
    @Published var errorMessage: String?

    /// Meditation settings (interval gongs, etc.)
    @Published var settings: MeditationSettings = .default

    /// Countdown seconds (0 if not in countdown)
    @Published var countdownSeconds: Int = 0

    /// Current affirmation index
    @Published var currentAffirmationIndex: Int = 0

    /// Whether currently in countdown phase
    var isCountdown: Bool {
        self.timerState == .countdown
    }

    /// Get current running affirmation
    var currentRunningAffirmation: String {
        self.runningAffirmations[self.currentAffirmationIndex % self.runningAffirmations.count]
    }

    /// Get current countdown affirmation
    var currentCountdownAffirmation: String {
        self.countdownAffirmations[self.currentAffirmationIndex % self.countdownAffirmations.count]
    }

    /// Formatted time string (MM:SS or countdown seconds)
    var formattedTime: String {
        if self.isCountdown {
            return "\(self.countdownSeconds)"
        }
        let minutes = self.remainingSeconds / 60
        let seconds = self.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        self.timerState == .idle && self.selectedMinutes > 0
    }

    /// Returns true if timer can be paused
    var canPause: Bool {
        self.timerState == .running
    }

    /// Returns true if timer can be resumed
    var canResume: Bool {
        self.timerState == .paused
    }

    /// Returns true if timer can be reset
    var canReset: Bool {
        self.timerState != .idle
    }

    // MARK: - Public Methods

    /// Starts the timer with selected duration
    func startTimer() {
        guard self.selectedMinutes > 0 else {
            Logger.viewModel.warning("Attempted to start timer with 0 minutes")
            return
        }
        Logger.viewModel.info("Starting timer from UI", metadata: ["minutes": self.selectedMinutes])
        // Rotate affirmation for next session
        self.currentAffirmationIndex = (self.currentAffirmationIndex + 1) % max(
            self.runningAffirmations.count,
            self.countdownAffirmations.count
        )
        self.timerService.start(durationMinutes: self.selectedMinutes)
    }

    /// Pauses the running timer
    func pauseTimer() {
        Logger.viewModel.debug("Pausing timer from UI")
        self.timerService.pause()
    }

    /// Resumes the paused timer
    func resumeTimer() {
        Logger.viewModel.debug("Resuming timer from UI")
        self.timerService.resume()
    }

    /// Resets the timer to initial state
    func resetTimer() {
        Logger.viewModel.debug("Resetting timer from UI")
        self.audioService.stopBackgroundAudio()
        self.timerService.reset()
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(self.settings.intervalGongsEnabled, forKey: MeditationSettings.Keys.intervalGongsEnabled)
        defaults.set(self.settings.intervalMinutes, forKey: MeditationSettings.Keys.intervalMinutes)
        defaults.set(self.settings.backgroundAudioMode.rawValue, forKey: MeditationSettings.Keys.backgroundAudioMode)
        Logger.viewModel.info("Saved settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundAudioMode": self.settings.backgroundAudioMode.rawValue
        ])
    }

    // MARK: Private

    // MARK: - Private Properties

    private let timerService: TimerServiceProtocol
    private let audioService: AudioServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var previousState: TimerState = .idle
    private var currentTimer: MeditationTimer?

    /// Affirmations for running state (rotated based on session)
    private var runningAffirmations: [String] {
        [
            NSLocalizedString("affirmation.running.1", comment: ""),
            NSLocalizedString("affirmation.running.2", comment: ""),
            NSLocalizedString("affirmation.running.3", comment: ""),
            NSLocalizedString("affirmation.running.4", comment: ""),
            NSLocalizedString("affirmation.running.5", comment: "")
        ]
    }

    /// Affirmations for countdown state (rotated)
    private var countdownAffirmations: [String] {
        [
            NSLocalizedString("affirmation.countdown.1", comment: ""),
            NSLocalizedString("affirmation.countdown.2", comment: ""),
            NSLocalizedString("affirmation.countdown.3", comment: ""),
            NSLocalizedString("affirmation.countdown.4", comment: "")
        ]
    }

    // MARK: - Private Methods

    private func setupBindings() {
        self.timerService.timerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timer in
                self?.updateFromTimer(timer)
            }
            .store(in: &self.cancellables)
    }

    private func updateFromTimer(_ timer: MeditationTimer) {
        self.currentTimer = timer
        self.timerState = timer.state
        self.remainingSeconds = timer.remainingSeconds
        self.totalSeconds = timer.totalSeconds
        self.progress = timer.progress
        self.countdownSeconds = timer.countdownSeconds

        // Detect state transitions
        self.handleStateTransition(from: self.previousState, to: timer.state, timer: timer)
        self.previousState = timer.state
    }

    private func handleStateTransition(from oldState: TimerState, to newState: TimerState, timer: MeditationTimer) {
        // Countdown → Running: Play start gong and start background audio
        if oldState == .countdown, newState == .running {
            Logger.viewModel.info("Countdown complete, playing start gong and starting background audio")
            self.playStartGong()
            self.startBackgroundAudio()
            return
        }

        // Running → Completed: Play completion sound and stop background audio
        if newState == .completed {
            Logger.viewModel.info("Timer completed, playing completion sound")
            self.audioService.stopBackgroundAudio()
            self.playCompletionSound()
            return
        }

        // Check for interval gongs while running
        if newState == .running, self.settings.intervalGongsEnabled {
            self.checkAndPlayIntervalGong(timer: timer)
        }
    }

    private func checkAndPlayIntervalGong(timer: MeditationTimer) {
        guard timer.shouldPlayIntervalGong(intervalMinutes: self.settings.intervalMinutes) else {
            return
        }

        Logger.viewModel.info("Playing interval gong", metadata: [
            "interval": self.settings.intervalMinutes,
            "remaining": timer.remainingSeconds
        ])

        self.playIntervalGong()

        // Mark that we played the gong
        if var updatedTimer = currentTimer {
            updatedTimer = updatedTimer.markIntervalGongPlayed()
            self.currentTimer = updatedTimer
        }
    }

    private func playStartGong() {
        do {
            try self.audioService.playStartGong()
        } catch {
            Logger.viewModel.error("Failed to play start gong", error: error)
            self.errorMessage = "Failed to play start sound: \(error.localizedDescription)"
        }
    }

    private func playIntervalGong() {
        do {
            try self.audioService.playIntervalGong()
        } catch {
            Logger.viewModel.error("Failed to play interval gong", error: error)
            self.errorMessage = "Failed to play interval sound: \(error.localizedDescription)"
        }
    }

    private func playCompletionSound() {
        do {
            try self.audioService.playCompletionSound()
        } catch {
            Logger.viewModel.error("Failed to play completion sound", error: error)
            self.errorMessage = "Failed to play sound: \(error.localizedDescription)"
        }
    }

    private func startBackgroundAudio() {
        do {
            try self.audioService.startBackgroundAudio(mode: self.settings.backgroundAudioMode)
        } catch {
            Logger.viewModel.error("Failed to start background audio", error: error)
            self.errorMessage = "Failed to start background audio: \(error.localizedDescription)"
        }
    }

    // MARK: - Settings Management

    private func loadSettings() {
        let defaults = UserDefaults.standard

        // Load background audio mode
        let backgroundAudioModeString = defaults.string(forKey: MeditationSettings.Keys.backgroundAudioMode)
        let backgroundAudioMode = backgroundAudioModeString
            .flatMap { BackgroundAudioMode(rawValue: $0) } ?? .silent

        self.settings = MeditationSettings(
            intervalGongsEnabled: defaults.bool(forKey: MeditationSettings.Keys.intervalGongsEnabled),
            intervalMinutes: defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes) == 0
                ? 5 : defaults.integer(forKey: MeditationSettings.Keys.intervalMinutes),
            backgroundAudioMode: backgroundAudioMode
        )
        Logger.viewModel.info("Loaded settings", metadata: [
            "intervalEnabled": self.settings.intervalGongsEnabled,
            "intervalMinutes": self.settings.intervalMinutes,
            "backgroundAudioMode": self.settings.backgroundAudioMode.rawValue
        ])
    }
}

// MARK: - Preview Support

extension TimerViewModel {
    /// Creates a view model with mocked services for previews
    static func preview(state: TimerState = .idle) -> TimerViewModel {
        let viewModel = TimerViewModel()
        viewModel.timerState = state

        switch state {
        case .idle:
            viewModel.remainingSeconds = 0
            viewModel.totalSeconds = 600
        case .countdown:
            viewModel.remainingSeconds = 600
            viewModel.totalSeconds = 600
            viewModel.countdownSeconds = 10
        case .running,
             .paused:
            viewModel.remainingSeconds = 300
            viewModel.totalSeconds = 600
            viewModel.progress = 0.5
        case .completed:
            viewModel.remainingSeconds = 0
            viewModel.totalSeconds = 600
            viewModel.progress = 1.0
        }

        return viewModel
    }
}
