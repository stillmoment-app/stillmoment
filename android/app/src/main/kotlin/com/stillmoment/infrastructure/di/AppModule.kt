package com.stillmoment.infrastructure.di

import android.content.Context
import com.stillmoment.data.local.GuidedMeditationSettingsDataStore
import com.stillmoment.data.local.PraxisDataStore
import com.stillmoment.data.repositories.CustomAudioRepositoryImpl
import com.stillmoment.data.repositories.GuidedMeditationRepositoryImpl
import com.stillmoment.data.repositories.MeditationSourceRepositoryImpl
import com.stillmoment.data.repositories.SoundCatalogRepositoryImpl
import com.stillmoment.data.repositories.TimerRepositoryImpl
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.repositories.PraxisRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AttunementResolverProtocol
import com.stillmoment.domain.services.AudioFocusManagerProtocol
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.ProgressSchedulerProtocol
import com.stillmoment.domain.services.SoundscapeResolverProtocol
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import com.stillmoment.domain.services.VibrationServiceProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import com.stillmoment.infrastructure.audio.AttunementResolver
import com.stillmoment.infrastructure.audio.AudioFocusManager
import com.stillmoment.infrastructure.audio.AudioPlayerService
import com.stillmoment.infrastructure.audio.AudioService
import com.stillmoment.infrastructure.audio.AudioSessionCoordinator
import com.stillmoment.infrastructure.audio.MediaPlayerFactory
import com.stillmoment.infrastructure.audio.ProgressScheduler
import com.stillmoment.infrastructure.audio.SoundscapeResolver
import com.stillmoment.infrastructure.audio.TimerForegroundServiceWrapper
import com.stillmoment.infrastructure.audio.VibrationService
import com.stillmoment.infrastructure.audio.VolumeAnimator
import com.stillmoment.infrastructure.logging.AndroidLogger
import com.stillmoment.infrastructure.network.UrlAudioDownloaderImpl
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module providing app-wide dependencies.
 * Binds repositories and services for dependency injection.
 */
@Suppress("TooManyFunctions") // DI module: one @Provides per binding is expected
@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    @Provides
    @Singleton
    fun provideApplicationContext(@ApplicationContext context: Context): Context {
        return context
    }

    @Provides
    @Singleton
    fun providePraxisRepository(impl: PraxisDataStore): PraxisRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideAudioFocusManager(impl: AudioFocusManager): AudioFocusManagerProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideAudioSessionCoordinator(coordinator: AudioSessionCoordinator): AudioSessionCoordinatorProtocol {
        return coordinator
    }

    @Provides
    @Singleton
    fun provideTimerRepository(impl: TimerRepositoryImpl): TimerRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideGuidedMeditationRepository(impl: GuidedMeditationRepositoryImpl): GuidedMeditationRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideGuidedMeditationSettingsRepository(
        impl: GuidedMeditationSettingsDataStore
    ): GuidedMeditationSettingsRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideAudioPlayerService(impl: AudioPlayerService): AudioPlayerServiceProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideMediaPlayerFactory(impl: MediaPlayerFactory): MediaPlayerFactoryProtocol {
        return impl
    }

    @Provides
    fun provideProgressScheduler(impl: ProgressScheduler): ProgressSchedulerProtocol {
        return impl
    }

    @Provides
    fun provideVolumeAnimator(impl: VolumeAnimator): VolumeAnimatorProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideLogger(impl: AndroidLogger): LoggerProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideAudioService(impl: AudioService): AudioServiceProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideTimerForegroundService(impl: TimerForegroundServiceWrapper): TimerForegroundServiceProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideCustomAudioRepository(impl: CustomAudioRepositoryImpl): CustomAudioRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideSoundCatalogRepository(impl: SoundCatalogRepositoryImpl): SoundCatalogRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideMeditationSourceRepository(impl: MeditationSourceRepositoryImpl): MeditationSourceRepository {
        return impl
    }

    @Provides
    @Singleton
    fun provideAttunementResolver(impl: AttunementResolver): AttunementResolverProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideSoundscapeResolver(impl: SoundscapeResolver): SoundscapeResolverProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideVibrationService(impl: VibrationService): VibrationServiceProtocol {
        return impl
    }

    @Provides
    @Singleton
    fun provideUrlAudioDownloader(impl: UrlAudioDownloaderImpl): UrlAudioDownloaderProtocol {
        return impl
    }
}
