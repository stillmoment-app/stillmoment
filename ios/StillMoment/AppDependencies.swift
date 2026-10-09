//
//  AppDependencies.swift
//  Still Moment
//
//  Composition Root (ios-055): the only place outside StillMomentApp where services
//  are created. Everything below is handed down through initializers (Pure DI).
//

import Foundation

/// All services of the app, created once in `live()` and passed down from `StillMomentApp`.
///
/// Rules (see `.claude/rules/ios-dependency-injection.md`):
/// - Only views that build a ViewModel receive this struct. ViewModels and services
///   never receive it — they get their individual dependencies.
/// - Services with app-wide state (audio conflict handling, keep-alive, waveform
///   de-duplication, in-memory library) exist exactly once.
/// - Services whose state belongs to one playback are created per player through the
///   `make…` factories, but still only here.
struct AppDependencies {
    // MARK: Internal

    // MARK: Timer & audio

    let audioService: AudioServiceProtocol
    let timerService: TimerServiceProtocol
    let clock: ClockProtocol
    let praxisRepository: PraxisRepository
    let backgroundSoundRepository: BackgroundSoundRepositoryProtocol
    let customAudioRepository: CustomAudioRepositoryProtocol
    let soundscapeResolver: SoundscapeResolverProtocol

    // MARK: Library

    let meditationService: GuidedMeditationServiceProtocol
    let metadataService: AudioMetadataServiceProtocol
    let meditationSourceRepository: MeditationSourceRepositoryProtocol
    let searchHistoryStore: SearchHistoryStore
    let guidedSettingsRepository: GuidedSettingsRepository
    let waveformProvider: WaveformProviderProtocol
    let downloadService: AudioDownloadServiceProtocol

    // MARK: Per-player services

    /// A fresh end-gong player for each opened player.
    let makeGongPlayer: () -> MeditationGongPlayerProtocol

    /// A fresh playback service for each opened player (holds that player's AVPlayer,
    /// remote commands and now-playing info).
    let makeAudioPlayerService: () -> AudioPlayerServiceProtocol

    /// Builds the production dependency graph. Call exactly once per app launch.
    @MainActor
    static func live() -> AppDependencies {
        let coordinator = AudioSessionCoordinator.shared
        let clock = SystemClock()
        let backgroundSoundRepository = BackgroundSoundRepository()
        let customAudioRepository = CustomAudioRepository()
        let soundscapeResolver = SoundscapeResolver(
            soundRepository: backgroundSoundRepository,
            customAudioRepository: customAudioRepository
        )
        let meditationService = GuidedMeditationService()
        let makeGongPlayer: () -> MeditationGongPlayerProtocol = { MeditationGongPlayer() }

        return AppDependencies(
            audioService: AudioService(
                coordinator: coordinator,
                soundRepository: backgroundSoundRepository,
                soundscapeResolver: soundscapeResolver
            ),
            timerService: TimerService(clock: clock),
            clock: clock,
            praxisRepository: UserDefaultsPraxisRepository(),
            backgroundSoundRepository: backgroundSoundRepository,
            customAudioRepository: customAudioRepository,
            soundscapeResolver: soundscapeResolver,
            meditationService: meditationService,
            metadataService: AudioMetadataService(),
            meditationSourceRepository: MeditationSourceRepository(),
            searchHistoryStore: UserDefaultsSearchHistoryStore(),
            guidedSettingsRepository: GuidedMeditationSettingsRepository(),
            waveformProvider: WaveformProvider(
                generationService: WaveformGenerationService(),
                cacheService: WaveformCacheService(),
                meditationService: meditationService
            ),
            downloadService: AudioDownloadService(),
            makeGongPlayer: makeGongPlayer,
            makeAudioPlayerService: Self.audioPlayerServiceFactory(
                coordinator: coordinator,
                soundRepository: backgroundSoundRepository,
                makeGongPlayer: makeGongPlayer
            )
        )
    }

    // MARK: Private

    private static func audioPlayerServiceFactory(
        coordinator: AudioSessionCoordinatorProtocol,
        soundRepository: BackgroundSoundRepositoryProtocol,
        makeGongPlayer: @escaping () -> MeditationGongPlayerProtocol
    ) -> () -> AudioPlayerServiceProtocol {
        {
            AudioPlayerService(
                coordinator: coordinator,
                nowPlayingProvider: SystemNowPlayingInfoProvider(),
                soundRepository: soundRepository,
                gongPlayer: makeGongPlayer()
            )
        }
    }
}

// MARK: - Wiring

/// How the app hands the shared services to its screens. `StillMomentApp` and the views
/// call these instead of picking fields themselves, so the wiring is one place and testable.
@MainActor
extension AppDependencies {
    func makeTimerViewModel() -> TimerViewModel {
        TimerViewModel(
            timerService: self.timerService,
            audioService: self.audioService,
            soundRepository: self.backgroundSoundRepository,
            praxisRepository: self.praxisRepository,
            customAudioRepository: self.customAudioRepository,
            soundscapeResolver: self.soundscapeResolver
        )
    }

    func makeGuidedListViewModel() -> GuidedMeditationsListViewModel {
        GuidedMeditationsListViewModel(
            meditationService: self.meditationService,
            metadataService: self.metadataService,
            audioService: self.audioService,
            meditationSourceRepository: self.meditationSourceRepository,
            searchHistoryStore: self.searchHistoryStore,
            waveformProvider: self.waveformProvider
        )
    }

    func makeFileOpenHandler() -> FileOpenHandler {
        FileOpenHandler(
            meditationService: self.meditationService,
            metadataService: self.metadataService
        )
    }

    /// A player gets fresh per-playback services and the shared library, waveforms and settings.
    func makePlayerViewModel(
        meditation: GuidedMeditation,
        preparationTimeSeconds: Int?
    ) -> GuidedMeditationPlayerViewModel {
        GuidedMeditationPlayerViewModel(
            meditation: meditation,
            preparationTimeSeconds: preparationTimeSeconds,
            playerService: self.makeAudioPlayerService(),
            meditationService: self.meditationService,
            waveformProvider: self.waveformProvider,
            clock: self.clock,
            gongPlayer: self.makeGongPlayer(),
            praxisRepository: self.praxisRepository
        )
    }
}
