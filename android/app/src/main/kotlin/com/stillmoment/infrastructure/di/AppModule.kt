package com.stillmoment.infrastructure.di

import android.content.Context
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.data.repositories.TimerRepositoryImpl
import com.stillmoment.domain.repositories.SettingsRepository
import com.stillmoment.domain.repositories.TimerRepository
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.infrastructure.audio.AudioSessionCoordinator
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
    fun provideSettingsRepository(
        settingsDataStore: SettingsDataStore
    ): SettingsRepository {
        return settingsDataStore
    }

    @Provides
    @Singleton
    fun provideAudioSessionCoordinator(
        coordinator: AudioSessionCoordinator
    ): AudioSessionCoordinatorProtocol {
        return coordinator
    }

    @Provides
    @Singleton
    fun provideTimerRepository(
        impl: TimerRepositoryImpl
    ): TimerRepository {
        return impl
    }
}
