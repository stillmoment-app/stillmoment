package com.stillmoment.domain.services

/**
 * Protocol for timer audio service.
 *
 * Defines the contract for playing gong sounds and managing background audio
 * during silent meditation. Implementation handles audio focus, looping,
 * and volume fading.
 *
 * Used by TimerViewModel for preview playback in the settings sheet.
 * Foreground service audio (gongs during timer, background audio) flows
 * through TimerForegroundServiceProtocol instead.
 */
interface AudioServiceProtocol {
    /**
     * Play a gong sound preview. Automatically stops any previous preview.
     * Uses a separate player to avoid interfering with timer playback.
     *
     * @param soundId ID of the gong sound to preview
     * @param volume Playback volume (0.0 to 1.0)
     */
    fun playGongPreview(soundId: String, volume: Float = 1.0f)

    /**
     * Play interval gong sound (for preview in settings).
     *
     * @param volume Playback volume (0.0 to 1.0)
     */
    fun playIntervalGong(volume: Float = 1.0f)

    /**
     * Stop the current gong preview. Idempotent - safe to call even if no preview is playing.
     */
    fun stopGongPreview()

    /**
     * Play a background sound preview. Plays for a short duration with fade-out.
     * Automatically stops any previous preview (gong or background).
     *
     * @param soundId ID of the background sound to preview
     * @param volume Playback volume (0.0 to 1.0)
     */
    fun playBackgroundPreview(soundId: String, volume: Float)

    /**
     * Stop the current background preview. Idempotent - safe to call even if no preview is playing.
     */
    fun stopBackgroundPreview()
}
