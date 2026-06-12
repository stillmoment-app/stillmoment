//
//  GuidedMeditationPlayerViewModel.swift
//  Still Moment
//
//  Application Layer - Guided Meditation Player ViewModel
//

import Combine
import Foundation
import OSLog

/// Emitted once when a guided meditation ends naturally (audio played to end).
///
/// Written to `@SceneStorage` by the View so the completion screen survives
/// app termination (shared-080).
struct CompletionEvent: Equatable {
    let meditationId: UUID
    let completedAt: Date
}

/// State of the preparation countdown
enum PreparationCountdownState: Equatable {
    case idle
    case active(PreparationCountdown)
    case finished
}

/// ViewModel for the Guided Meditation Player View
///
/// Manages:
/// - Audio playback state and controls
/// - Progress tracking and seeking
/// - Background audio and lock screen integration
/// - Preparation countdown before playback
@MainActor
final class GuidedMeditationPlayerViewModel: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        meditation: GuidedMeditation,
        preparationTimeSeconds: Int? = nil,
        playerService: AudioPlayerServiceProtocol = AudioPlayerService(),
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        clock: ClockProtocol = SystemClock(),
        gongPlayer: MeditationGongPlayerProtocol = MeditationGongPlayer(),
        praxisRepository: PraxisRepository = UserDefaultsPraxisRepository()
    ) {
        self.meditation = meditation
        self.preparationTimeSeconds = preparationTimeSeconds
        self.playerService = playerService
        self.meditationService = meditationService
        self.clock = clock
        self.gongPlayer = gongPlayer
        self.praxisRepository = praxisRepository

        self.setupBindings()
        // Remote controls will be configured in play() after audio session is activated
        // This ensures iOS properly registers lock screen controls
    }

    // MARK: Internal

    // MARK: - Published Properties

    @Published var meditation: GuidedMeditation
    @Published var playbackState: PlaybackState = .idle
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var errorMessage: String?
    @Published private(set) var completionEvent: CompletionEvent?

    // MARK: - Preparation Countdown

    @Published private(set) var countdownState: PreparationCountdownState = .idle

    /// Preparation time in seconds before MP3 starts (nil = disabled)
    private let preparationTimeSeconds: Int?

    /// Tracks whether the session has started (countdown or playback began)
    /// Used to prevent countdown from triggering again on resume
    private(set) var hasSessionStarted = false

    /// Formatted current time string (MM:SS or HH:MM:SS)
    var formattedCurrentTime: String {
        self.formatTime(self.currentTime)
    }

    /// Formatted remaining time string (MM:SS or HH:MM:SS) — counts down to the trim end
    var formattedRemainingTime: String {
        let remaining = max(self.meditation.effectiveEnd - self.currentTime, 0)
        return self.formatTime(remaining)
    }

    /// Restzeit fuer das "NOCH … MIN"-Label im neuen Player-Layout.
    ///
    /// Identisch mit `formattedRemainingTime` — eigene Property, weil der
    /// View-Aufruf so semantisch klar bleibt ("Minuten-Label im Atemkreis-Player").
    var formattedRemainingMinutes: String {
        self.formattedRemainingTime
    }

    /// Progress within the effective (trimmed) range as a value between 0 and 1
    var progress: Double {
        let effectiveDuration = self.meditation.effectiveDuration
        guard effectiveDuration > 0 else {
            return 0
        }
        let elapsed = self.currentTime - self.meditation.effectiveStart
        return min(max(elapsed / effectiveDuration, 0), 1)
    }

    /// Whether the player is currently playing
    var isPlaying: Bool {
        self.playbackState == .playing
    }

    /// Whether playback is paused (distinct from idle/loading/finished/failed).
    ///
    /// Used by the view to switch the remaining-time label format — only `.paused`
    /// should show the "PAUSIERT"-Prefix, not transient states like `.loading`.
    var isPaused: Bool {
        self.playbackState == .paused
    }

    /// Whether the guided meditation has completed naturally (audio reached end)
    var isCompleted: Bool {
        self.playbackState == .finished
    }

    /// Visuelle Phase des Players.
    ///
    /// - `.preRoll` solange die Vorbereitung laeuft.
    /// - `.playing` ansonsten (auch bei Pause, Loading, Idle, Finished —
    ///   der Atemkreis sieht in all diesen Zustaenden gleich aus).
    var phase: MeditationPhase {
        self.isPreparing ? .preRoll : .playing
    }

    // MARK: - Preparation Countdown Properties

    /// Whether preparation countdown is currently active
    var isPreparing: Bool {
        if case .active = self.countdownState {
            return true
        }
        return false
    }

    /// Whether Zen Mode is active: tab bar should be hidden during active session
    ///
    /// Active when preparation countdown is running, meditation is playing or
    /// paused, or the completion/thank-you screen is shown. Pause keeps the
    /// player as the active surface — switching tabs is not the intended action.
    var isZenMode: Bool {
        self.isPreparing || self.isPlaying || self.playbackState == .paused || self.isCompleted
    }

    /// Remaining countdown seconds (for UI)
    var remainingCountdownSeconds: Int {
        if case let .active(countdown) = countdownState {
            return countdown.remainingSeconds
        }
        return 0
    }

    /// Progress for countdown ring (0.0 to 1.0)
    var countdownProgress: Double {
        if case let .active(countdown) = countdownState {
            return countdown.progress
        }
        return 0
    }

    // MARK: - Public Methods

    /// Loads and prepares the audio for playback
    func loadAudio() async {
        self.errorMessage = nil
        self.completionEvent = nil

        Logger.audioPlayer.info("Loading audio", metadata: [
            "meditation": self.meditation.name,
            "teacher": self.meditation.teacher
        ])

        // Get local file URL via service (resolves path and verifies file exists)
        guard let fileURL = meditationService.fileURL(for: meditation) else {
            Logger.audioPlayer.error("No file URL for meditation or file missing")
            self.errorMessage = NSLocalizedString("error.audioFileNotFound", comment: "Audio file not found error")
            return
        }

        do {
            try await self.playerService.load(url: fileURL, meditation: self.meditation)
            // shared-106: end gong plays at the trim end / file end on the lock screen;
            // the sound is chosen per meditation, the volume follows the timer settings
            if self.meditation.endGongEnabled {
                self.playerService.configureEndGong(
                    soundId: self.meditation.gongSoundId,
                    volume: self.praxisRepository.load().gongVolume
                )
            }
            Logger.audioPlayer.info("Audio loaded successfully")
        } catch {
            Logger.audioPlayer.error("Failed to load audio", error: error)
            self.errorMessage = NSLocalizedString("error.audioLoadFailed", comment: "Failed to load audio")
        }
    }

    /// Toggles play/pause
    func togglePlayPause() {
        do {
            switch self.playbackState {
            case .playing:
                self.playerService.pause()
                Logger.audioPlayer.debug("Paused playback")
            case .paused,
                 .idle:
                try self.playerService.play()
                Logger.audioPlayer.debug("Started playback")
            case .finished:
                // Reset to the effective beginning (skips a trimmed intro) and play
                try self.playerService.seek(to: self.meditation.effectiveStart)
                try self.playerService.play()
                Logger.audioPlayer.debug("Restarted playback")
            default:
                break
            }
        } catch {
            Logger.audioPlayer.error("Failed to toggle playback", error: error)
            self.errorMessage = NSLocalizedString("error.playbackFailed", comment: "Playback error")
        }
    }

    /// Stops playback and returns to beginning
    func stop() {
        self.playerService.stop()
        Logger.audioPlayer.debug("Stopped playback")
    }

    /// Seeks to a specific time
    ///
    /// - Parameter time: Time in seconds to seek to
    func seek(to time: TimeInterval) {
        do {
            try self.playerService.seek(to: time)
            Logger.audioPlayer.debug("Seeked to \(time)s")
        } catch {
            Logger.audioPlayer.error("Failed to seek", error: error)
            self.errorMessage = NSLocalizedString("error.seekFailed", comment: "Seek error")
        }
    }

    /// Skips forward by a given number of seconds (stops at the trim end)
    ///
    /// - Parameter seconds: Seconds to skip forward
    func skipForward(by seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, self.meditation.effectiveEnd)
        self.seek(to: newTime)
    }

    /// Skips backward by a given number of seconds (stops at the trim start)
    ///
    /// - Parameter seconds: Seconds to skip backward
    func skipBackward(by seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, self.meditation.effectiveStart)
        self.seek(to: newTime)
    }

    /// Cleans up resources when done
    func cleanup() {
        self.countdownTimer?.cancel()
        self.countdownTimer = nil
        self.breathPauseTimer?.cancel()
        self.breathPauseTimer = nil
        self.gongPlayer.stop()
        self.playerService.cleanup()
        self.cancellables.removeAll()
        Logger.audioPlayer.debug("Cleaned up player resources")
    }

    // MARK: - Preparation Countdown Methods

    /// Starts playback (with countdown if configured)
    ///
    /// - First call with preparation time: starts countdown, then plays
    /// - First call without preparation time: plays immediately
    /// - Subsequent calls: toggles play/pause (no countdown)
    func startPlayback() {
        // Don't start if already counting down or while the start gong sequence runs
        guard !self.isPreparing, !self.isStartGongSequenceActive else {
            return
        }

        // If session already started, just toggle play/pause (no countdown on resume)
        guard !self.hasSessionStarted else {
            self.togglePlayPause()
            return
        }

        // Mark session as started
        self.hasSessionStarted = true

        // First start - use countdown if configured
        if let prepTime = preparationTimeSeconds {
            self.startCountdown(seconds: prepTime)
        } else if self.meditation.startGongEnabled {
            self.startGongSequence()
        } else {
            self.togglePlayPause()
        }
    }

    // MARK: Private

    // MARK: - Dependencies

    /// Breath pause between start gong and meditation audio (shared-106)
    private static let breathPauseSeconds: TimeInterval = 2.0

    private let playerService: AudioPlayerServiceProtocol
    private let meditationService: GuidedMeditationServiceProtocol
    private let clock: ClockProtocol
    private let gongPlayer: MeditationGongPlayerProtocol
    private let praxisRepository: PraxisRepository
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: AnyCancellable?
    private var breathPauseTimer: AnyCancellable?

    /// True while the start gong rings and during the following breath pause —
    /// blocks further startPlayback taps until the meditation audio runs
    private var isStartGongSequenceActive = false

    // MARK: - Private Methods

    private func setupBindings() {
        // Bind playback state; emit completionEvent once on natural end
        self.playerService.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else {
                    return
                }
                self.playbackState = state
                if state == .finished, self.completionEvent == nil {
                    self.completionEvent = CompletionEvent(
                        meditationId: self.meditation.id,
                        completedAt: self.clock.now()
                    )
                }
            }
            .store(in: &self.cancellables)

        // Bind current time
        self.playerService.currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$currentTime)

        // Bind duration
        self.playerService.duration
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Countdown Methods

    private func startCountdown(seconds: Int) {
        let countdown = PreparationCountdown(totalSeconds: seconds)
        self.countdownState = .active(countdown)

        // Start silent background audio to keep app active during countdown
        do {
            try self.playerService.startSilentBackgroundAudio()
        } catch {
            Logger.audioPlayer.error("Failed to start silent background audio", error: error)
        }

        self.countdownTimer = self.clock.schedule(interval: 1.0) { [weak self] in
            self?.tickCountdown()
        }
    }

    private func tickCountdown() {
        guard case let .active(countdown) = countdownState else {
            return
        }

        let ticked = countdown.tick()

        if ticked.isFinished {
            self.countdownTimer?.cancel()
            self.countdownTimer = nil
            self.countdownState = .finished
            if self.meditation.startGongEnabled {
                // shared-106: gong rings in the still-active silent-audio session,
                // then the breath pause and the atomic transition follow
                self.isStartGongSequenceActive = true
                self.playStartGongThenTransition()
            } else {
                self.transitionToPlayback()
            }
        } else {
            self.countdownState = .active(ticked)
        }
    }

    /// Uses the atomic transition to prevent an audio gap when the screen is locked:
    /// playback starts BEFORE silent audio stops, so iOS never suspends the app.
    private func transitionToPlayback() {
        do {
            try self.playerService.transitionFromSilentToPlayback()
        } catch {
            Logger.audioPlayer.error("Failed to transition to playback", error: error)
            self.errorMessage = NSLocalizedString("error.playbackFailed", comment: "Playback error")
        }
    }

    // MARK: - Start Gong Sequence (shared-106)

    /// Starts the meditation with a gong: silent keep-alive → gong → breath pause → audio.
    ///
    /// Reuses the countdown machinery (silent background audio + atomic transition)
    /// so the whole sequence survives a locked screen.
    private func startGongSequence() {
        self.isStartGongSequenceActive = true
        do {
            try self.playerService.startSilentBackgroundAudio()
        } catch {
            Logger.audioPlayer.error("Failed to start silent background audio", error: error)
        }
        self.playStartGongThenTransition()
    }

    private func playStartGongThenTransition() {
        self.gongPlayer.play(
            soundId: self.meditation.gongSoundId,
            volume: self.praxisRepository.load().gongVolume
        ) { [weak self] in
            self?.startBreathPause()
        }
    }

    private func startBreathPause() {
        self.breathPauseTimer = self.clock.schedule(interval: Self.breathPauseSeconds) { [weak self] in
            self?.finishBreathPause()
        }
    }

    private func finishBreathPause() {
        self.breathPauseTimer?.cancel()
        self.breathPauseTimer = nil
        self.isStartGongSequenceActive = false
        self.transitionToPlayback()
    }
}
