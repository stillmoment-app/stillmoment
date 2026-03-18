//
//  AudioService.swift
//  Still Moment
//
//  Infrastructure - Audio Service Implementation
//

import AudioToolbox
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
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository(),
        customAudioRepository: CustomAudioRepositoryProtocol? = nil,
        attunementResolver: AttunementResolverProtocol? = nil,
        soundscapeResolver: SoundscapeResolverProtocol? = nil,
        backgroundPreviewDuration: TimeInterval = 3.0,
        fadeOutDuration: TimeInterval = 0.5
    ) {
        self.coordinator = coordinator
        self.soundRepository = soundRepository
        self.customAudioRepository = customAudioRepository
        let customRepo = customAudioRepository ?? CustomAudioRepository()
        self.attunementResolver = attunementResolver ?? AttunementResolver(
            customAudioRepository: customRepo
        )
        self.soundscapeResolver = soundscapeResolver ?? SoundscapeResolver(
            soundRepository: soundRepository,
            customAudioRepository: customRepo
        )
        self.backgroundPreviewDuration = backgroundPreviewDuration
        self.fadeOutDuration = fadeOutDuration
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

    convenience init() {
        self.init(
            coordinator: AudioSessionCoordinator.shared,
            customAudioRepository: CustomAudioRepository()
        )
    }

    // MARK: - Deinit

    deinit {
        self.cancellables.removeAll()
        self.cleanupPreviewPlayers()
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
        if soundId == GongSound.vibrationId {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }
        // Audio session is already active via activateTimerSession()
        try self.playGongSound(soundId: soundId, volume: volume)
    }

    func playIntervalGong(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing interval gong", metadata: ["soundId": soundId, "volume": "\(volume)"])
        if soundId == GongSound.vibrationId {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }
        // Audio session is already active via activateTimerSession()
        try self.playGongSound(soundId: soundId, volume: volume)
    }

    func playGongPreview(soundId: String, volume: Float) throws {
        Logger.audio.info("Playing gong preview", metadata: ["soundId": soundId, "volume": "\(volume)"])

        // Stop any previous previews (mutual exclusion)
        self.stopGongPreview()
        self.stopBackgroundPreview()
        self.stopMeditationPreview()

        if soundId == GongSound.vibrationId {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }

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

        // Stop any previous previews (mutual exclusion)
        self.stopBackgroundPreview()
        self.stopGongPreview()
        self.stopMeditationPreview()

        // Don't play preview for silent sound - just stop any running previews
        if soundId == "silent" {
            Logger.audio.debug("Skipping preview for silent sound")
            return
        }

        _ = try self.coordinator.requestAudioSession(for: .preview)
        let soundURL = try self.resolveBackgroundSoundURL(soundId: soundId)

        do {
            self.backgroundPreviewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.backgroundPreviewPlayer?.volume = volume
            self.backgroundPreviewPlayer?.prepareToPlay()
            self.backgroundPreviewPlayer?.play()

            // Schedule fade-out after preview duration
            // Note: Timer must be created on main thread for RunLoop.main
            self.backgroundPreviewTimer = Timer.scheduledTimer(
                withTimeInterval: self.backgroundPreviewDuration,
                repeats: false
            ) { [weak self] _ in
                self?.fadeOutBackgroundPreview()
            }

            Logger.audio.info(
                "Background preview started",
                metadata: ["file": soundURL.lastPathComponent, "volume": "\(volume)"]
            )
        } catch let error as AudioServiceError {
            throw error
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

        let soundURL = try self.resolveBackgroundSoundURL(soundId: soundId)
        try self.startBackgroundAudioPlayer(url: soundURL, volume: volume)
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

    let coordinator: AudioSessionCoordinatorProtocol
    private let soundRepository: BackgroundSoundRepositoryProtocol
    let customAudioRepository: CustomAudioRepositoryProtocol?
    let attunementResolver: AttunementResolverProtocol
    let soundscapeResolver: SoundscapeResolverProtocol
    private let backgroundPreviewDuration: TimeInterval
    let fadeOutDuration: TimeInterval
    private let gongCompletionSubject = PassthroughSubject<Void, Never>()
    let introductionCompletionSubject = PassthroughSubject<Void, Never>()
    let gongPlayerDelegate: GongPlayerDelegate
    let introductionPlayerDelegate: IntroductionPlayerDelegate
    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer?
    var introductionPlayer: AVAudioPlayer?
    var keepAlivePlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    private var backgroundPreviewPlayer: AVAudioPlayer?
    var introductionPreviewPlayer: AVAudioPlayer?
    var meditationPreviewPlayer: AVAudioPlayer?
    private var backgroundPreviewTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Target volume for background audio (stored for fade resume)
    private var targetVolume: Float = 0.15

    /// Whether a timer session is currently active (for interruption recovery)
    var timerSessionActive = false

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
}

// MARK: - Background Audio Helpers

private extension AudioService {
    /// Sets up and starts the background audio player with fade-in effect
    func startBackgroundAudioPlayer(url: URL, volume: Float) throws {
        do {
            self.backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
            self.backgroundAudioPlayer?.numberOfLoops = -1 // Loop indefinitely

            // Store target volume for resume and start at 0 for fade in
            self.targetVolume = volume
            self.backgroundAudioPlayer?.volume = 0

            self.backgroundAudioPlayer?.prepareToPlay()
            self.backgroundAudioPlayer?.play()

            // Fade in to target volume
            self.backgroundAudioPlayer?.setVolume(
                self.targetVolume,
                fadeDuration: Self.fadeInDuration
            )

            Logger.audio.info(
                "Background audio started with fade in",
                metadata: ["file": url.lastPathComponent, "targetVolume": "\(volume)"]
            )
        } catch {
            Logger.audio.error("Failed to start background audio", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    /// Resolves a background sound URL by ID via the SoundscapeResolver.
    func resolveBackgroundSoundURL(soundId: String) throws -> URL {
        try self.soundscapeResolver.resolveAudioURL(id: soundId)
    }
}

// MARK: - Audio Interruption Handling

private extension AudioService {
    func setupAudioInterruptionHandling() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &self.cancellables)

        Logger.audio.debug("Audio interruption handling configured")
    }

    func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            Logger.audio.info("Audio interruption began")

        case .ended:
            // Note: AVAudioSessionInterruptionOptionKey may be absent on older iOS versions.
            // We always attempt keep-alive recovery when a timer session is active —
            // timerSessionActive is set to false by cleanupTimerPlayers() on full audio-focus loss
            // (e.g., phone call), so the guard prevents spurious restarts after real takeovers.
            let optionsValue = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            Logger.audio.info(
                "Audio interruption ended",
                metadata: ["shouldResume": "\(options.contains(.shouldResume))"]
            )
            if self.timerSessionActive {
                self.restartKeepAliveAfterInterruption()
            }

        @unknown default:
            Logger.audio.warning("Unknown audio interruption type")
        }
    }
}

// MARK: - Gong Playback

private extension AudioService {
    func playGongSound(soundId: String, volume: Float, isPreview: Bool = false) throws {
        let gongSound = GongSound.findOrDefault(byId: soundId)
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

    func fadeOutBackgroundPreview() {
        guard let player = self.backgroundPreviewPlayer else {
            return
        }

        Logger.audio.debug("Fading out background preview")
        player.setVolume(0, fadeDuration: self.fadeOutDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeOutDuration) { [weak self] in
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
        self.introductionPreviewPlayer?.stop()
        self.introductionPreviewPlayer = nil
        self.meditationPreviewPlayer?.stop()
        self.meditationPreviewPlayer = nil
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
