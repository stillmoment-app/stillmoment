package com.stillmoment.presentation.navigation

/**
 * Wires the player's completion callbacks against the persisted marker (shared-080).
 *
 * All transitions of the marker live here, so that no way out of the player can
 * forget to clear it: only the natural end sets it, while loading a new
 * meditation and every exit from the player clear it. A marker left behind
 * makes the completion screen reappear on the next app start (AK-2).
 *
 * Takes the marker as two lambdas instead of the ViewModel itself — state
 * hoisting, as the Compose rules require for anything handed down the tree.
 *
 * Mirrors iOS `CompletionMarkerWriter`.
 */
class PlayerCompletionWiring(
    private val setMarker: () -> Unit,
    private val clearMarker: () -> Unit,
    private val leavePlayer: () -> Unit
) {

    /** The meditation played to its end — remember it across process death. */
    fun onMeditationFinish() {
        setMarker()
    }

    /** A new session begins — an older completion is no longer pending. */
    fun onMeditationLoad() {
        clearMarker()
    }

    /**
     * An incoming file or finished download interrupts the session — the app
     * navigates to the import flow rather than back through the player.
     */
    fun onSessionInterrupted() {
        clearMarker()
    }

    /**
     * The user leaves the player — via the close button or by tapping the
     * completion screen away. Forget the marker, then navigate.
     */
    fun onLeavePlayer() {
        clearMarker()
        leavePlayer()
    }
}
