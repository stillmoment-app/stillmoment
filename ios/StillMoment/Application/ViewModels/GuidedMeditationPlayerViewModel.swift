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

/// State of the central resting line below the wave (shared-109).
///
/// `remaining` carries the already-formatted `mm:ss` remaining time; `paused` and
/// `finished` are special states the view renders as plain words.
enum RemainingLineState: Equatable {
    case remaining(String)
    case paused
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
        playerService: AudioPlayerServiceProtocol,
        meditationService: GuidedMeditationServiceProtocol,
        waveformProvider: WaveformProviderProtocol,
        clock: ClockProtocol,
        gongPlayer: MeditationGongPlayerProtocol,
        praxisRepository: PraxisRepository
    ) {
        self.meditation = meditation
        self.preparationTimeSeconds = preparationTimeSeconds
        self.playerService = playerService
        self.meditationService = meditationService
        self.waveformProvider = waveformProvider
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

    // MARK: - Waveform (shared-109)

    /// Precomputed waveform of the whole file (nil while loading or after a failure).
    /// The samples span the full `meditation.duration`, not the trimmed range.
    @Published private(set) var waveform: MeditationWaveform?

    /// True when waveform generation failed (e.g. exotic format). The player stays fully
    /// functional — the window renders a plain baseline instead of amplitudes.
    @Published private(set) var waveformLoadFailed = false

    // MARK: - Scrub (shared-109)

    /// True while the user is dragging the wave to scrub. Pauses the pulse and replaces
    /// the remaining-time line with the large live position.
    @Published private(set) var isDragging = false

    /// Live position during a drag (absolute file time, clamped to the trim range).
    /// Drives the window center and the live-position readout while dragging.
    @Published private(set) var dragPosition: TimeInterval = 0

    // MARK: - Preparation Countdown

    @Published private(set) var countdownState: PreparationCountdownState = .idle

    /// True while the start gong rings and during the following breath pause (shared-106).
    /// The view keeps the calm pre-roll ring then, without a countdown number (shared-143).
    @Published private(set) var isStartGongSequenceActive = false

    /// Preparation time in seconds before MP3 starts (nil = disabled)
    private let preparationTimeSeconds: Int?

    /// Tracks whether the session has started (countdown or playback began)
    /// Used to prevent countdown from triggering again on resume
    private(set) var hasSessionStarted = false

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
    ///
    /// Ignored before the meditation audio begins — a tap during preparation, start gong or
    /// breath pause must not start the meditation early (shared-143). The sequence starts
    /// it exactly once itself. After an interruption aborted that sequence, it starts over
    /// when the system gives the sound back, or with the next tap — whichever comes first
    /// (ios-065, shared-146).
    func togglePlayPause() {
        guard !self.isBeforeAudio else {
            return
        }
        guard self.hasSessionStarted else {
            self.startPlayback()
            return
        }
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
    /// Ignored before the meditation audio begins (shared-143): the meditation always
    /// starts at the beginning of its playable range.
    ///
    /// - Parameter time: Time in seconds to seek to
    func seek(to time: TimeInterval) {
        guard !self.isBeforeAudio else {
            return
        }
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
        self.restartsPreRollAfterInterruption = false
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
        guard !self.isBeforeAudio else {
            return
        }
        self.restartsPreRollAfterInterruption = false

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
    private let waveformProvider: WaveformProviderProtocol
    private let clock: ClockProtocol
    private let gongPlayer: MeditationGongPlayerProtocol
    private let praxisRepository: PraxisRepository
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: AnyCancellable?
    private var breathPauseTimer: AnyCancellable?

    /// Position at which the current drag began (absolute file time, clamped to the trim
    /// range). The view maps the cumulative drag translation against this fixed anchor.
    private(set) var dragStartTime: TimeInterval = 0

    /// Whether playback was running when the current drag began — decides whether to resume
    /// on release.
    private var dragWasPlaying = false

    /// Set when an interruption aborted the pre-roll; it starts over when the system gives
    /// the sound back (shared-146). A tap on Play or closing the player clears it.
    private var restartsPreRollAfterInterruption = false

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

        self.playerService.interruptionBegan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleInterruption()
            }
            .store(in: &self.cancellables)

        self.playerService.interruptionEnded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleInterruptionEnded()
            }
            .store(in: &self.cancellables)
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
            if self.meditation.startGongEnabled {
                // Hand over to the start gong before the countdown ends, in the same
                // main-actor turn, so the playing view never flashes up in between (shared-143)
                self.isStartGongSequenceActive = true
                self.countdownState = .finished
                // shared-106: gong rings in the still-active silent-audio session,
                // then the breath pause and the atomic transition follow
                self.playStartGongThenTransition()
            } else {
                self.countdownState = .finished
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
            // An interruption may have aborted the sequence before this completion arrived
            guard let self, self.isStartGongSequenceActive else {
                return
            }
            self.startBreathPause()
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

    // MARK: - Interruption (ios-065, shared-146)

    /// During playback the service has already paused (and resumes by itself when the system
    /// gives the sound back); a scrub in progress must not resume on release. Before the
    /// meditation audio begins, the pre-roll is aborted.
    private func handleInterruption() {
        self.dragWasPlaying = false
        if self.isBeforeAudio {
            self.abortPreRoll()
        }
    }

    /// The system gave the sound back: an aborted pre-roll starts over, so the meditation
    /// still begins exactly once.
    private func handleInterruptionEnded() {
        guard self.restartsPreRollAfterInterruption else {
            return
        }
        Logger.audioPlayer.info("Restarting pre-roll after interruption")
        self.startPlayback()
    }

    /// Preparation, start gong and breath pause stop and the player waits paused at the
    /// beginning, until the interruption ends with the sound given back or the user taps Play.
    private func abortPreRoll() {
        self.countdownTimer?.cancel()
        self.countdownTimer = nil
        self.breathPauseTimer?.cancel()
        self.breathPauseTimer = nil
        self.gongPlayer.stop()
        self.playerService.stopSilentBackgroundAudio()
        self.countdownState = .idle
        self.isStartGongSequenceActive = false
        self.hasSessionStarted = false
        self.restartsPreRollAfterInterruption = true
        Logger.audioPlayer.info("Pre-roll aborted by interruption")
    }
}

// MARK: - Waveform Window & Scrub (shared-109)

extension GuidedMeditationPlayerViewModel {
    // MARK: Waveform loading (AK-1, AK-8)

    /// Loads the precomputed waveform for the scrolling window.
    ///
    /// Runs independently of `loadAudio()` so a cold cache (first open, on-demand
    /// generation) never blocks playback. On failure the window falls back to a plain
    /// baseline — scrub, times and the mini overview stay fully functional.
    func loadWaveform() async {
        do {
            let loaded = try await self.waveformProvider.waveform(for: self.meditation)
            self.waveform = loaded
            self.waveformLoadFailed = false
        } catch {
            Logger.audioPlayer.error("Failed to load waveform", error: error)
            self.waveform = nil
            self.waveformLoadFailed = true
        }
    }

    // MARK: Scrub intents (AK-2, AK-3)

    /// Begins a scrub: grabbing the wave pauses playback and anchors the drag at the
    /// current position (clamped into the trim range). Ignored before the meditation audio
    /// begins — there is nothing to scrub yet (shared-143).
    func beginScrub() {
        guard !self.isBeforeAudio else {
            return
        }
        let anchored = self.clampToScrubBounds(self.currentTime)
        self.dragStartTime = anchored
        self.dragPosition = anchored
        self.dragWasPlaying = self.isPlaying
        self.isDragging = true
        if self.isPlaying {
            self.playerService.pause()
            Logger.audioPlayer.debug("Scrub began — paused playback")
        }
    }

    /// Updates the live drag position to an absolute file time, clamped to the trim range.
    func scrub(to time: TimeInterval) {
        self.dragPosition = self.clampToScrubBounds(time)
    }

    /// Ends a scrub: seeks to the live position and resumes playback if it was running
    /// before the grab (and the position is not at the very end).
    func endScrub() {
        let target = self.dragPosition
        self.isDragging = false
        self.seek(to: target)
        if self.dragWasPlaying, target < self.meditation.effectiveEnd {
            do {
                try self.playerService.play()
                Logger.audioPlayer.debug("Scrub ended — resumed playback")
            } catch {
                Logger.audioPlayer.error("Failed to resume after scrub", error: error)
                self.errorMessage = NSLocalizedString("error.playbackFailed", comment: "Playback error")
            }
        }
        self.dragWasPlaying = false
    }

    /// Seeks to a fraction (0…1) of the trimmed track — the mini overview's absolute seek.
    ///
    /// Position `p` maps to `effectiveStart + p · effectiveDuration`, so a tap always lands
    /// inside the playable range regardless of trim (AK-5).
    func seek(toFraction fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        let target = self.meditation.effectiveStart + clamped * self.meditation.effectiveDuration
        self.seek(to: target)
    }

    /// Clamps an absolute file time into the playable (trimmed) range.
    private func clampToScrubBounds(_ time: TimeInterval) -> TimeInterval {
        min(max(time, self.scrubBounds.lowerBound), self.scrubBounds.upperBound)
    }
}
