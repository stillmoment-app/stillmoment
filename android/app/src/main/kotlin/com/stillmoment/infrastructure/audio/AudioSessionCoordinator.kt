package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Singleton coordinator for exclusive audio session access between features.
 *
 * Ensures only one audio source (Timer or Guided Meditation) is active at a time.
 * When a new source requests access, the current source is notified via its
 * registered conflict handler, allowing it to gracefully stop playback.
 *
 * This mirrors the iOS AudioSessionCoordinator implementation for feature parity.
 */
@Singleton
class AudioSessionCoordinator
@Inject
constructor() : AudioSessionCoordinatorProtocol {
    private val _activeSource = MutableStateFlow<AudioSource?>(null)
    override val activeSource: StateFlow<AudioSource?> = _activeSource.asStateFlow()

    private val conflictHandlers = mutableMapOf<AudioSource, () -> Unit>()

    override fun registerConflictHandler(source: AudioSource, handler: () -> Unit) {
        conflictHandlers[source] = handler
    }

    override fun requestAudioSession(source: AudioSource): Boolean {
        val current = _activeSource.value

        // If different source is active, notify it of conflict
        if (current != null && current != source) {
            conflictHandlers[current]?.invoke()
        }

        _activeSource.value = source
        return true
    }

    override fun releaseAudioSession(source: AudioSource) {
        if (_activeSource.value == source) {
            _activeSource.value = null
        }
    }
}
