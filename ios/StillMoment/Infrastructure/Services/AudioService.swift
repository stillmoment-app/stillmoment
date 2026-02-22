//
//  AudioService.swift
//  Still Moment
//
//  Infrastructure - Audio Service Implementation
//

import AVFoundation
import Combine
import Foundation
import OSLog

/// Concrete implementation of audio service using AVFoundation
final class AudioService: AudioServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        coordinator: AudioSessionCoordinatorProtocol,
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository()
    ) {
        self.coordinator = coordinator
        self.soundRepository = soundRepository
        self.gongPlayerDelegate = GongPlayerDelegate { [gongCompletionSubject] in
            gongCompletionSubject.send()
        }
        self.introductionPlayerDelegate = IntroductionPlayerDelegate { [introductionCompletionSubject] in
            introductionCompletionSubject.send()
        }
        self.setupAudioInterruptionHandling()
        self.registerConflictHandler()
    }

    // MARK: - Constants

    /// Duration for fade in effect (10 seconds for smooth meditation experience after start gong)
    private static let fadeInDuration: TimeInterval = 10.0

    /// Duration for background preview before fade-out starts
    private static let backgroundPreviewDuration: TimeInterval = 3.0

    /// Duration for fade-out effect
    private static let fadeOutDuration: TimeInterval = 0.5

    convenience init() {
        self.init(coordinator: AudioSessionCoordinator.shared)
    }

    // MARK: - Deinit

    deinit {
        self.cancellables.removeAll()
        self.backgroundPreviewTimer?.invalidate()
        self.backgroundPreviewTimer = nil
        self.backgroundPreviewPlayer?.stop()
        self.backgroundPreviewPlayer = nil
        self.timerSessionActive = false
        self.keepAlivePlayer?.stop()
        self.keepAlivePlayer = nil
        self.stopBackgroundAudio()
        stop()
    }

    // MARK: Internal

    var gongCompletionPublisher: AnyPublisher<Void, Never> {
        self.gongCompletionSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    /// Configures the audio session for timer use and starts a silent keep-alive audio loop.
    ///
    /// The keep-alive loop plays `silence.mp3` to prevent iOS from suspending the app
    /// during phases without audible audio (Preparation, Start-Gong→Introduction transition).
    /// It is automatically replaced when `startBackgroundAudio()` is called.
    /// See ADR-004 for details.
    func configureAudioSession() throws {
        // Request audio session through coordinator
        _ = try self.coordinator.requestAudioSession(for: .timer)
        self.startKeepAliveAudio()
    }

    /// Activates a timer session: configures audio session and starts always-on keep-alive.
    ///
    /// Keep-alive runs continuously from timer start to timer end. It is NOT stopped when
    /// background audio, introduction, or gongs play — the silent audio at volume 0.01
    /// does not interfere with other audio players.
    ///
    /// Call once at timer start. The only counterpart is `deactivateTimerSession()`.
    func activateTimerSession() throws {
        _ = try self.coordinator.requestAudioSession(for: .timer)
        self.timerSessionActive = true
        self.startKeepAliveAudio()
        Logger.audio.info("Timer session activated (always-on keep-alive)")
    }

    /// Deactivates the timer session: stops keep-alive and releases the audio session.
    ///
    /// This is the ONLY place where keep-alive is stopped during a timer lifecycle.
    func deactivateTimerSession() {
        self.timerSessionActive = false
        self.stopKeepAliveAudio()
        self.coordinator.releaseAudioSession(for: .timer)
        Logger.audio.info("Timer session deactivated")
    }

    func playStartGong(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing start gong", metadata: ["soundId": soundId, "volume": "\(volume)"])
        // Audio session is already active via activateTimerSession()
        try self.playGongSound(soundId: soundId, volume: volume)
    }

    func playIntervalGong(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing interval gong", metadata: ["soundId": soundId, "volume": "\(volume)"])
        // Audio session is already active via activateTimerSession()
        try self.playGongSound(soundId: soundId, volume: volume)
    }

    func playGongPreview(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing gong preview", metadata: ["soundId": soundId, "volume": "\(volume)"])

        // Stop any previous previews (mutual exclusion: gong and background)
        self.stopGongPreview()
        self.stopBackgroundPreview()

        _ = try self.coordinator.requestAudioSession(for: .preview)
        try self.playGongSound(soundId: soundId, volume: volume, isPreview: true)
    }

    func stopGongPreview() {
        guard self.previewPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping gong preview")
        self.previewPlayer?.stop()
        self.previewPlayer = nil
        self.coordinator.releaseAudioSession(for: .preview)
    }

    func playBackgroundPreview(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing background preview", metadata: ["soundId": soundId, "volume": "\(volume)"])

        // Stop any previous previews (mutual exclusion: gong and background)
        self.stopBackgroundPreview()
        self.stopGongPreview()

        // Don't play preview for silent sound - just stop any running previews
        if soundId == "silent" {
            Logger.audio.debug("Skipping preview for silent sound")
            return
        }

        _ = try self.coordinator.requestAudioSession(for: .preview)

        // Get sound from repository
        guard let sound = self.soundRepository.getSound(byId: soundId) else {
            Logger.audio.error("Background sound not found for preview", metadata: ["soundId": soundId])
            throw AudioServiceError.soundFileNotFound
        }

        // Get file URL from bundle
        let (name, ext) = self.parseFilename(sound.filename)
        guard let soundURL = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "BackgroundAudio"
        ) else {
            Logger.audio.error("Background audio file not found for preview", metadata: ["filename": sound.filename])
            throw AudioServiceError.soundFileNotFound
        }

        do {
            self.backgroundPreviewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.backgroundPreviewPlayer?.volume = volume
            self.backgroundPreviewPlayer?.prepareToPlay()
            self.backgroundPreviewPlayer?.play()

            // Schedule fade-out after preview duration
            // Note: Timer must be created on main thread for RunLoop.main
            self.backgroundPreviewTimer = Timer.scheduledTimer(
                withTimeInterval: Self.backgroundPreviewDuration,
                repeats: false
            ) { [weak self] _ in
                self?.fadeOutBackgroundPreview()
            }

            Logger.audio.info(
                "Background preview started",
                metadata: ["sound": sound.name, "volume": "\(volume)"]
            )
        } catch {
            Logger.audio.error("Failed to play background preview", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundPreview() {
        // Cancel fade-out timer
        self.backgroundPreviewTimer?.invalidate()
        self.backgroundPreviewTimer = nil

        guard self.backgroundPreviewPlayer != nil else {
            return
        }

        Logger.audio.debug("Stopping background preview")
        self.backgroundPreviewPlayer?.stop()
        self.backgroundPreviewPlayer = nil
        self.coordinator.releaseAudioSession(for: .preview)
    }

    func startBackgroundAudio(soundId: String, volume: Float) throws {
        Logger.audio.info("Starting background audio", metadata: ["soundId": soundId, "volume": "\(volume)"])

        // Keep-alive runs in parallel — no need to stop it. The silent audio at 0.01 volume
        // does not interfere with background audio. See shared-059.

        // Get sound from repository
        guard let sound = self.soundRepository.getSound(byId: soundId) else {
            Logger.audio.error("Background sound not found", metadata: ["soundId": soundId])
            throw AudioServiceError.soundFileNotFound
        }

        // Get file URL from bundle
        let (name, ext) = self.parseFilename(sound.filename)
        guard let soundURL = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "BackgroundAudio"
        ) else {
            Logger.audio.error("Background audio file not found in bundle", metadata: ["filename": sound.filename])
            throw AudioServiceError.soundFileNotFound
        }

        do {
            self.backgroundAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.backgroundAudioPlayer?.numberOfLoops = -1 // Loop indefinitely

            // Store target volume for resume and start at 0 for fade in
            // Use the volume parameter from settings instead of sound.volume
            self.targetVolume = volume
            self.backgroundAudioPlayer?.volume = 0

            self.backgroundAudioPlayer?.prepareToPlay()
            self.backgroundAudioPlayer?.play()

            // Fade in to target volume
            self.backgroundAudioPlayer?.setVolume(self.targetVolume, fadeDuration: Self.fadeInDuration)

            Logger.audio.info(
                "Background audio started with fade in",
                metadata: ["sound": sound.name, "targetVolume": "\(volume)"]
            )
        } catch {
            Logger.audio.error("Failed to start background audio", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundAudio() {
        guard self.backgroundAudioPlayer != nil else {
            return
        }

        Logger.audio.debug("Stopping background audio")
        self.backgroundAudioPlayer?.stop()
        self.backgroundAudioPlayer = nil
    }

    func playCompletionSound(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing completion sound", metadata: ["soundId": soundId, "volume": "\(volume)"])
        // Audio session is still active — deactivateTimerSession() is called after completion
        try self.playGongSound(soundId: soundId, volume: volume)
    }

    func stop() {
        Logger.audio.debug("Stopping all audio playback")
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.stopIntroduction()
        self.stopBackgroundAudio()

        // Keep-alive is managed by activateTimerSession/deactivateTimerSession.
        // stop() does NOT touch keep-alive — it may still be needed if timer is active.
        // Release audio session when stopping all audio
        self.timerSessionActive = false
        self.coordinator.releaseAudioSession(for: .timer)
    }

    // MARK: Private

    private let coordinator: AudioSessionCoordinatorProtocol
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let gongCompletionSubject = PassthroughSubject<Void, Never>()
    let introductionCompletionSubject = PassthroughSubject<Void, Never>()
    private let gongPlayerDelegate: GongPlayerDelegate
    let introductionPlayerDelegate: IntroductionPlayerDelegate
    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer?
    var introductionPlayer: AVAudioPlayer?
    private var keepAlivePlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    private var backgroundPreviewPlayer: AVAudioPlayer?
    private var backgroundPreviewTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Target volume for background audio (stored for fade resume)
    private var targetVolume: Float = 0.15

    /// Whether a timer session is currently active (for interruption recovery)
    private var timerSessionActive = false

    // MARK: - Keep-Alive Audio

    /// Starts a silent audio loop to keep the audio session alive.
    /// Runs continuously from activateTimerSession() to deactivateTimerSession().
    /// No-op if keep-alive is already playing.
    private func startKeepAliveAudio() {
        guard self.keepAlivePlayer == nil else {
            return
        }

        guard let url = Bundle.main.url(
            forResource: "silence",
            withExtension: "mp3",
            subdirectory: "BackgroundAudio"
        ) else {
            Logger.audio.warning("Keep-alive audio file not found")
            return
        }

        do {
            self.keepAlivePlayer = try AVAudioPlayer(contentsOf: url)
            self.keepAlivePlayer?.numberOfLoops = -1
            self.keepAlivePlayer?.volume = 0.01
            self.keepAlivePlayer?.prepareToPlay()
            self.keepAlivePlayer?.play()
            Logger.audio.debug("Keep-alive audio started")
        } catch {
            Logger.audio.error("Failed to start keep-alive audio", error: error)
        }
    }

    /// Restarts keep-alive after an audio interruption (e.g., phone call).
    /// iOS pauses AVAudioPlayers during interruption — we need to resume the keep-alive
    /// to prevent app suspension if the timer is still active.
    private func restartKeepAliveAfterInterruption() {
        if let player = self.keepAlivePlayer, !player.isPlaying {
            player.play()
            Logger.audio.info("Keep-alive resumed after interruption")
        } else if self.keepAlivePlayer == nil {
            self.startKeepAliveAudio()
            Logger.audio.info("Keep-alive restarted after interruption")
        }
    }

    /// Stops the silent keep-alive audio loop.
    private func stopKeepAliveAudio() {
        guard self.keepAlivePlayer != nil else {
            return
        }
        self.keepAlivePlayer?.stop()
        self.keepAlivePlayer = nil
        Logger.audio.debug("Keep-alive audio stopped")
    }

    // MARK: - Private Methods

    /// Parses a filename into name and extension components
    /// - Parameter filename: The full filename (e.g., "forest_ambience.mp3")
    /// - Returns: Tuple of (name, extension) where extension may be nil
    func parseFilename(_ filename: String) -> (name: String, ext: String?) {
        let components = filename.components(separatedBy: ".")
        let name = components.first ?? filename
        let ext = components.count > 1 ? components.last : nil
        return (name, ext)
    }

    private func setupAudioInterruptionHandling() {
        // Handle audio session interruptions (e.g., phone call) using Combine
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &self.cancellables)

        Logger.audio.debug("Audio interruption handling configured")
    }

    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            Logger.audio.info("Audio interruption began")
            // iOS automatically pauses audio, we just log it

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                Logger.audio.info("Audio interruption ended, resuming")
                // Restart keep-alive if timer session is still active
                if self.timerSessionActive {
                    self.restartKeepAliveAfterInterruption()
                }
            } else {
                Logger.audio.info("Audio interruption ended without resume option")
            }

        @unknown default:
            Logger.audio.warning("Unknown audio interruption type")
        }
    }

    /// Plays a gong sound by ID from GongSounds folder
    /// - Parameters:
    ///   - soundId: The GongSound ID to play
    ///   - volume: Playback volume (0.0 to 1.0)
    ///   - isPreview: If true, uses the preview player instead of main audio player
    private func playGongSound(soundId: String, volume: Float, isPreview: Bool = false) throws {
        let gongSound = GongSound.findOrDefault(byId: soundId)

        // Parse filename to get name and extension
        let (name, ext) = self.parseFilename(gongSound.filename)

        // Resolve URL: soft-interval tone is in root Resources, others in GongSounds/
        let soundURL: URL? = if gongSound.id == "soft-interval" {
            Bundle.main.url(forResource: name, withExtension: ext)
        } else {
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "GongSounds")
        }

        guard let soundURL else {
            Logger.audio.error(
                "Gong sound file not found",
                metadata: ["soundId": soundId, "filename": gongSound.filename]
            )
            throw AudioServiceError.soundFileNotFound
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = volume
            if !isPreview {
                player.delegate = self.gongPlayerDelegate
            }
            player.prepareToPlay()
            player.play()

            if isPreview {
                self.previewPlayer = player
            } else {
                self.audioPlayer = player
            }

            Logger.audio.info(
                "Gong playing",
                metadata: ["soundId": soundId, "volume": "\(volume)", "isPreview": "\(isPreview)"]
            )
        } catch {
            Logger.audio.error("Failed to play gong", error: error, metadata: ["soundId": soundId])
            throw AudioServiceError.playbackFailed
        }
    }

    /// Fades out and stops the background preview player
    private func fadeOutBackgroundPreview() {
        guard let player = self.backgroundPreviewPlayer else {
            return
        }

        Logger.audio.debug("Fading out background preview")

        // Use AVAudioPlayer's built-in fade
        player.setVolume(0, fadeDuration: Self.fadeOutDuration)

        // Stop and clean up after fade completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeOutDuration) { [weak self] in
            self?.cleanupPreviewPlayers()
            self?.coordinator.releaseAudioSession(for: .preview)
            Logger.audio.debug("Background preview fade-out complete")
        }
    }
}

// MARK: - Player Cleanup

private extension AudioService {
    /// Cleans up all preview players without releasing the audio session.
    /// Used by conflict handler and fade-out completion.
    func cleanupPreviewPlayers() {
        self.previewPlayer?.stop()
        self.previewPlayer = nil
        self.backgroundPreviewTimer?.invalidate()
        self.backgroundPreviewTimer = nil
        self.backgroundPreviewPlayer?.stop()
        self.backgroundPreviewPlayer = nil
    }

    /// Cleans up all timer players (including keep-alive) without releasing the audio session.
    /// Used by conflict handler when another source takes over.
    func cleanupTimerPlayers() {
        self.timerSessionActive = false
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.introductionPlayer?.stop()
        self.introductionPlayer = nil
        self.backgroundAudioPlayer?.stop()
        self.backgroundAudioPlayer = nil
        self.keepAlivePlayer?.stop()
        self.keepAlivePlayer = nil
    }
}

// MARK: - Conflict Handlers

private extension AudioService {
    /// Registers conflict handlers to stop audio when another source becomes active
    func registerConflictHandler() {
        self.coordinator.registerConflictHandler(for: .timer) { [weak self] in
            guard let self else {
                return
            }

            Logger.audio.info("Timer audio stopping - another source became active")
            self.cleanupTimerPlayers()
        }

        self.coordinator.registerConflictHandler(for: .preview) { [weak self] in
            guard let self else {
                return
            }

            Logger.audio.info("Preview audio stopping - another source became active")
            self.cleanupPreviewPlayers()
        }
    }
}

// MARK: - GongPlayerDelegate

/// AVAudioPlayerDelegate that notifies when a gong finishes playing.
/// Used to sequence introduction audio after the start gong completes.
/// Always fires onFinish — even on interruption (successfully: false) — to prevent
/// the state machine from getting stuck in `.startGong`.
private class GongPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        self.onFinish()
    }
}

// MARK: - Future Enhancement: Custom Sound Support

extension AudioService {
    /// Loads a custom sound file from the app bundle
    /// - Parameter filename: Name of the sound file (e.g., "tibetan-singing-bowl-55786-10s.mp3")
    /// - Returns: URL to the sound file
    func loadCustomSound(filename: String) -> URL? {
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: nil
        ) else {
            return nil
        }
        return url
    }
}
