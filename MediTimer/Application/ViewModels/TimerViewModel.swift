//
//  TimerViewModel.swift
//  MediTimer
//
//  Application Layer - Timer ViewModel
//

import Foundation
import Combine
import OSLog

/// ViewModel managing timer state and user interactions
@MainActor
final class TimerViewModel: ObservableObject {
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

    // MARK: - Private Properties

    private let timerService: TimerServiceProtocol
    private let audioService: AudioServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        timerService: TimerServiceProtocol = TimerService(),
        audioService: AudioServiceProtocol = AudioService()
    ) {
        self.timerService = timerService
        self.audioService = audioService

        setupBindings()
        configureAudio()
    }

    // MARK: - Public Methods

    /// Starts the timer with selected duration
    func startTimer() {
        guard selectedMinutes > 0 else {
            Logger.viewModel.warning("Attempted to start timer with 0 minutes")
            return
        }
        Logger.viewModel.info("Starting timer from UI", metadata: ["minutes": selectedMinutes])
        timerService.start(durationMinutes: selectedMinutes)
    }

    /// Pauses the running timer
    func pauseTimer() {
        Logger.viewModel.debug("Pausing timer from UI")
        timerService.pause()
    }

    /// Resumes the paused timer
    func resumeTimer() {
        Logger.viewModel.debug("Resuming timer from UI")
        timerService.resume()
    }

    /// Resets the timer to initial state
    func resetTimer() {
        Logger.viewModel.debug("Resetting timer from UI")
        timerService.reset()
    }

    /// Formatted time string (MM:SS)
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        timerState == .idle && selectedMinutes > 0
    }

    /// Returns true if timer can be paused
    var canPause: Bool {
        timerState == .running
    }

    /// Returns true if timer can be resumed
    var canResume: Bool {
        timerState == .paused
    }

    /// Returns true if timer can be reset
    var canReset: Bool {
        timerState != .idle
    }

    // MARK: - Private Methods

    private func setupBindings() {
        timerService.timerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timer in
                self?.updateFromTimer(timer)
            }
            .store(in: &cancellables)
    }

    private func updateFromTimer(_ timer: MeditationTimer) {
        timerState = timer.state
        remainingSeconds = timer.remainingSeconds
        totalSeconds = timer.totalSeconds
        progress = timer.progress

        // Play sound when completed
        if timer.state == .completed {
            Logger.viewModel.info("Timer completed, playing sound")
            playCompletionSound()
        }
    }

    private func configureAudio() {
        do {
            try audioService.configureAudioSession()
        } catch {
            Logger.viewModel.error("Audio configuration failed", error: error)
            errorMessage = "Failed to configure audio: \(error.localizedDescription)"
        }
    }

    private func playCompletionSound() {
        do {
            try audioService.playCompletionSound()
        } catch {
            Logger.viewModel.error("Failed to play completion sound", error: error)
            errorMessage = "Failed to play sound: \(error.localizedDescription)"
        }
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
        case .running, .paused:
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
