package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioFocusManagerProtocol
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
 * Also manages system AudioFocus to properly handle interruptions from phone calls,
 * other apps, and system events. When audio focus is lost, the active source is
 * paused (not stopped). When the system gives focus back after a temporary loss, the
 * active source's resume handler runs, if it registered one (shared-146).
 *
 * This mirrors the iOS AudioSessionCoordinator implementation for feature parity.
 */
@Singleton
class AudioSessionCoordinator
@Inject
constructor(
    private val audioFocusManager: AudioFocusManagerProtocol
) : AudioSessionCoordinatorProtocol {
    private val _activeSource = MutableStateFlow<AudioSource?>(null)
    override val activeSource: StateFlow<AudioSource?> = _activeSource.asStateFlow()

    private val conflictHandlers = mutableMapOf<AudioSource, () -> Unit>()
    private val pauseHandlers = mutableMapOf<AudioSource, () -> Unit>()
    private val resumeHandlers = mutableMapOf<AudioSource, () -> Unit>()

    override fun registerConflictHandler(source: AudioSource, handler: () -> Unit) {
        conflictHandlers[source] = handler
    }

    override fun registerPauseHandler(source: AudioSource, handler: () -> Unit) {
        pauseHandlers[source] = handler
    }

    override fun registerResumeHandler(source: AudioSource, handler: () -> Unit) {
        resumeHandlers[source] = handler
    }

    override fun requestAudioSession(source: AudioSource): Boolean {
        val current = _activeSource.value

        // If different source is active, notify it of conflict
        if (current != null && current != source) {
            conflictHandlers[current]?.invoke()
        }

        // Request system audio focus
        val granted = audioFocusManager.requestFocus(
            // Interruption began (phone call, other app) - pause the active source
            onFocusLost = { _activeSource.value?.let { pauseHandlers[it]?.invoke() } },
            // The system gave the sound back after a temporary loss - resume the active source
            onFocusGained = { _activeSource.value?.let { resumeHandlers[it]?.invoke() } }
        )

        if (!granted) {
            return false
        }

        _activeSource.value = source
        return true
    }

    override fun releaseAudioSession(source: AudioSource) {
        if (_activeSource.value == source) {
            audioFocusManager.releaseFocus()
            _activeSource.value = null
        }
    }
}
