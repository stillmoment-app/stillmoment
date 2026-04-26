package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

/**
 * Activity-scoped ViewModel that persists a "meditation finished naturally"
 * marker across system-initiated process death.
 *
 * Behaviour mirrors iOS `@SceneStorage`:
 * - Survives OS termination caused by memory pressure or backgrounding.
 * - Is cleared when the user swipes the app away (intentional dismissal).
 *
 * Used by [com.stillmoment.presentation.navigation.StillMomentNavHost] to decide
 * whether to show the completion overlay on app start. The marker is read once
 * (snapshot pattern) so that the overlay is only triggered for state that was
 * already persisted on launch — it does not flip live while the player is
 * actively running.
 *
 * See ticket shared-080.
 */
@HiltViewModel
class CompletionOverlayViewModel
@Inject
constructor(
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    /**
     * The marker value at the time this ViewModel was constructed.
     *
     * Read once per ViewModel lifetime so callers can take a stable snapshot
     * at app start. Subsequent [setMarker]/[clearMarker] calls update the
     * persisted value but do not change this property.
     */
    val isMarkerSetInitially: Boolean = savedStateHandle.get<Boolean>(KEY) == true

    /**
     * Persists that a guided meditation just finished naturally.
     *
     * Called from the player when audio reaches its natural end. Active
     * dismissals (close button, audio session conflict, file-open stop signal)
     * must NOT call this method — see ticket shared-080 for the rules.
     */
    fun setMarker() {
        savedStateHandle[KEY] = true
    }

    /**
     * Removes the persisted marker.
     *
     * Called when the user dismisses the completion overlay or starts a new
     * meditation.
     */
    fun clearMarker() {
        savedStateHandle[KEY] = false
    }

    private companion object {
        const val KEY = "meditation_completion_marker"
    }
}
