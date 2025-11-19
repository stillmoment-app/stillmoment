//
//  GuidedMeditationPlayerViewModel.swift
//  Still Moment
//
//  Application Layer - Guided Meditation Player ViewModel
//

import Combine
import Foundation
import OSLog

/// ViewModel for the Guided Meditation Player View
///
/// Manages:
/// - Audio playback state and controls
/// - Progress tracking and seeking
/// - Background audio and lock screen integration
@MainActor
final class GuidedMeditationPlayerViewModel: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        meditation: GuidedMeditation,
        playerService: AudioPlayerServiceProtocol = AudioPlayerService(),
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService()
    ) {
        self.meditation = meditation
        self.playerService = playerService
        self.meditationService = meditationService

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

    /// Formatted current time string (MM:SS or HH:MM:SS)
    var formattedCurrentTime: String {
        self.formatTime(self.currentTime)
    }

    /// Formatted remaining time string (MM:SS or HH:MM:SS)
    var formattedRemainingTime: String {
        let remaining = max(duration - self.currentTime, 0)
        return self.formatTime(remaining)
    }

    /// Progress as a value between 0 and 1
    var progress: Double {
        guard self.duration > 0 else {
            return 0
        }
        return self.currentTime / self.duration
    }

    /// Whether the player is currently playing
    var isPlaying: Bool {
        self.playbackState == .playing
    }

    // MARK: - Public Methods

    /// Loads and prepares the audio for playback
    func loadAudio() async {
        self.errorMessage = nil

        Logger.audioPlayer.info("Loading audio", metadata: [
            "meditation": self.meditation.effectiveName,
            "teacher": self.meditation.effectiveTeacher
        ])

        do {
            // Resolve bookmark to URL
            let url = try meditationService.resolveBookmark(self.meditation.fileBookmark)

            // Start accessing security-scoped resource
            guard self.meditationService.startAccessingSecurityScopedResource(url) else {
                throw GuidedMeditationError.fileAccessDenied
            }

            defer {
                meditationService.stopAccessingSecurityScopedResource(url)
            }

            // Load audio
            try await self.playerService.load(url: url, meditation: self.meditation)

            Logger.audioPlayer.info("Audio loaded successfully")
        } catch {
            Logger.audioPlayer.error("Failed to load audio", error: error)
            self.errorMessage = "Failed to load audio: \(error.localizedDescription)"
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
                // Reset to beginning and play
                try self.playerService.seek(to: 0)
                try self.playerService.play()
                Logger.audioPlayer.debug("Restarted playback")
            default:
                break
            }
        } catch {
            Logger.audioPlayer.error("Failed to toggle playback", error: error)
            self.errorMessage = "Playback error: \(error.localizedDescription)"
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
            self.errorMessage = "Seek error: \(error.localizedDescription)"
        }
    }

    /// Skips forward by a given number of seconds
    ///
    /// - Parameter seconds: Seconds to skip forward
    func skipForward(by seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, self.duration)
        self.seek(to: newTime)
    }

    /// Skips backward by a given number of seconds
    ///
    /// - Parameter seconds: Seconds to skip backward
    func skipBackward(by seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        self.seek(to: newTime)
    }

    /// Cleans up resources when done
    func cleanup() {
        self.playerService.cleanup()
        self.cancellables.removeAll()
        Logger.audioPlayer.debug("Cleaned up player resources")
    }

    // MARK: Private

    // MARK: - Dependencies

    private let playerService: AudioPlayerServiceProtocol
    private let meditationService: GuidedMeditationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Methods

    private func setupBindings() {
        // Bind playback state
        self.playerService.state
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$playbackState)

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
}
