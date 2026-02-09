package com.stillmoment.infrastructure.audio

import android.content.Context
import com.stillmoment.domain.services.TimerForegroundServiceProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Wrapper that delegates to TimerForegroundService static companion methods.
 *
 * Provides an injectable, testable abstraction over the Android foreground
 * service so ViewModels can depend on TimerForegroundServiceProtocol
 * instead of calling static methods directly.
 */
@Singleton
class TimerForegroundServiceWrapper
@Inject
constructor(
    private val context: Context
) : TimerForegroundServiceProtocol {
    override fun startService(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float) {
        TimerForegroundService.startService(context, soundId, soundVolume, gongSoundId, gongVolume)
    }

    override fun stopService() {
        TimerForegroundService.stopService(context)
    }

    override fun playGong(gongSoundId: String, gongVolume: Float) {
        TimerForegroundService.playGong(context, gongSoundId, gongVolume)
    }

    override fun playIntervalGong(gongSoundId: String, gongVolume: Float) {
        TimerForegroundService.playIntervalGong(context, gongSoundId, gongVolume)
    }

    override fun pauseAudio() {
        TimerForegroundService.pauseAudio(context)
    }

    override fun resumeAudio() {
        TimerForegroundService.resumeAudio(context)
    }
}
