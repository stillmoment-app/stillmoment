package com.stillmoment.domain.services

import com.stillmoment.domain.models.AudioSource
import kotlinx.coroutines.flow.StateFlow

/**
 * Protocol for coordinating exclusive audio session access between features.
 *
 * Only one audio source (Timer or Guided Meditation) can be active at a time.
 * When a new source requests access, the current source is notified via its
 * registered conflict handler and must release the session.
 *
 * This mirrors the iOS AudioSessionCoordinatorProtocol for feature parity.
 */
interface AudioSessionCoordinatorProtocol {
    /**
     * The currently active audio source, or null if no source is active.
     */
    val activeSource: StateFlow<AudioSource?>

    /**
     * Register a conflict handler for a specific audio source.
     * The handler is invoked when another source requests the audio session.
     *
     * @param source The audio source registering the handler
     * @param handler The callback to invoke when a conflict occurs
     */
    fun registerConflictHandler(source: AudioSource, handler: () -> Unit)

    /**
     * Request exclusive audio session access for a source.
     *
     * If another source is currently active, its conflict handler is invoked
     * before granting access to the requesting source.
     *
     * @param source The audio source requesting access
     * @return true if access was granted
     */
    fun requestAudioSession(source: AudioSource): Boolean

    /**
     * Release the audio session for a source.
     *
     * Only releases if the specified source is currently active.
     *
     * @param source The audio source releasing the session
     */
    fun releaseAudioSession(source: AudioSource)
}
