package com.stillmoment.domain.services

/**
 * Protocol for timer foreground service operations.
 *
 * Abstracts the Android foreground service so the ViewModel does not
 * depend on concrete infrastructure classes or static companion methods.
 * The implementation wraps Android Intent-based service communication.
 */
interface TimerForegroundServiceProtocol {
    /**
     * Start the foreground service with background audio and notification.
     *
     * @param soundId Background sound identifier
     * @param soundVolume Background sound volume (0.0 to 1.0)
     * @param gongSoundId Gong sound identifier for start/completion
     * @param gongVolume Gong playback volume (0.0 to 1.0)
     */
    fun startService(soundId: String, soundVolume: Float, gongSoundId: String, gongVolume: Float)

    /**
     * Stop the foreground service and release audio resources.
     */
    fun stopService()

    /**
     * Play a gong sound through the foreground service.
     *
     * @param gongSoundId Gong sound identifier
     * @param gongVolume Gong playback volume (0.0 to 1.0)
     */
    fun playGong(gongSoundId: String, gongVolume: Float)

    /**
     * Play an interval gong sound through the foreground service.
     *
     * @param gongSoundId Interval gong sound identifier
     * @param gongVolume Gong playback volume (0.0 to 1.0)
     */
    fun playIntervalGong(gongSoundId: String, gongVolume: Float)

    /**
     * Update background audio (start or change sound).
     * Called when transitioning to Running state after the start gong.
     *
     * @param soundId Background sound identifier
     * @param soundVolume Background sound volume (0.0 to 1.0)
     */
    fun updateBackgroundAudio(soundId: String, soundVolume: Float)

    /**
     * Pause background audio immediately (no fade).
     */
    fun pauseAudio()

    /**
     * Resume background audio with fade in.
     */
    fun resumeAudio()
}
