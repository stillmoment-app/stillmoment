package com.stillmoment.domain.services

import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow

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

    /**
     * Current playback position of the active meditation preview in milliseconds.
     *
     * Updates roughly every 100 ms while a preview is playing (shared-098).
     * Drops back to 0 when the preview stops, switches or finishes.
     */
    val meditationPreviewPositionFlow: StateFlow<Long>

    /**
     * Total duration of the active meditation preview in milliseconds.
     *
     * Set when [playMeditationPreview] starts a new preview, cleared back to 0
     * on stop / switch / completion. UI uses this to scale the slider range.
     */
    val meditationPreviewDurationFlow: StateFlow<Long>

    /**
     * Emits exactly once when an active meditation preview reaches the natural
     * end of the audio file. Does NOT fire on explicit [stopMeditationPreview].
     *
     * ViewModel collects this to clear `previewingMeditationId` so the play
     * button flips back and the slider fades out (shared-098).
     */
    val meditationPreviewCompletionFlow: SharedFlow<Unit>

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

    /**
     * Play a guided meditation preview from a content URI.
     * Automatically stops any previous preview.
     * Uses AudioSource.PREVIEW (not GUIDED_MEDITATION).
     *
     * @param fileUri Content URI string of the meditation file (SAF)
     */
    fun playMeditationPreview(fileUri: String)

    /**
     * Stop the current meditation preview with a short fade-out (~0.3s).
     * Idempotent - safe to call even if no preview is playing.
     */
    fun stopMeditationPreview()

    /**
     * Seek the active meditation preview to the given position. Audio keeps
     * playing through the seek (Apple-Music-style scrubbing, shared-098).
     * Idempotent / no-op when no preview is active.
     *
     * @param positionMs Target position in milliseconds, clamped to `[0, duration]`.
     */
    fun seekMeditationPreview(positionMs: Long)
}
