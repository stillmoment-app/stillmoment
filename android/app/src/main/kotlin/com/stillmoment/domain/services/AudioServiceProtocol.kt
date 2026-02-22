package com.stillmoment.domain.services

import kotlinx.coroutines.flow.SharedFlow

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
 *
 * Completion flows are shared between the foreground service and ViewModel
 * (AudioService is a singleton injected into both).
 */
interface AudioServiceProtocol {
    /** Emits when a start/completion gong finishes playing */
    val gongCompletionFlow: SharedFlow<Unit>

    /** Emits when introduction audio finishes playing */
    val introductionCompletionFlow: SharedFlow<Unit>

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
     * @param soundId ID of the interval gong sound to play
     * @param volume Playback volume (0.0 to 1.0)
     */
    fun playIntervalGong(soundId: String, volume: Float = 1.0f)

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
