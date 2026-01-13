package com.stillmoment.infrastructure.di

import android.content.Context
import com.stillmoment.data.local.GuidedMeditationSettingsDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.data.repositories.GuidedMeditationRepositoryImpl
import com.stillmoment.data.repositories.TimerRepositoryImpl
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioFocusManagerProtocol
import com.stillmoment.domain.services.AudioPlayerServiceProtocol
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.ProgressSchedulerProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import com.stillmoment.infrastructure.audio.AudioFocusManager
import com.stillmoment.infrastructure.audio.AudioPlayerService
import com.stillmoment.infrastructure.audio.AudioSessionCoordinator
import com.stillmoment.infrastructure.audio.MediaPlayerFactory
import com.stillmoment.infrastructure.audio.ProgressScheduler
import com.stillmoment.infrastructure.audio.VolumeAnimator
import com.stillmoment.infrastructure.logging.AndroidLogger
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
    fun provideSettingsRepository(settingsDataStore: SettingsDataStore): SettingsRepository {
        return settingsDataStore
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
}
