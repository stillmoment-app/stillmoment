package com.stillmoment.presentation.navigation

import androidx.lifecycle.SavedStateHandle
import com.stillmoment.presentation.viewmodel.CompletionOverlayViewModel
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for [PlayerCompletionWiring].
 *
 * Reusing a [SavedStateHandle] in a fresh [CompletionOverlayViewModel] is what
 * the next app start sees: the system hands previously persisted state back to
 * a new ViewModel. So "does the next start show the completion screen?" is
 * expressible as a plain unit test.
 */
class PlayerCompletionWiringTest {

    private val savedStateHandle = SavedStateHandle()
    private val marker = CompletionOverlayViewModel(savedStateHandle)
    private var didLeavePlayer = false

    private val wiring = PlayerCompletionWiring(
        setMarker = marker::setMarker,
        clearMarker = marker::clearMarker,
        leavePlayer = { didLeavePlayer = true }
    )

    /** What the next app start would show. */
    private fun nextStartShowsCompletionScreen(): Boolean =
        CompletionOverlayViewModel(savedStateHandle).isMarkerSetInitially

    @Test
    fun `a meditation that ended naturally shows the completion screen on the next start`() {
        wiring.onMeditationFinish()

        assertTrue(nextStartShowsCompletionScreen())
    }

    @Test
    fun `dismissing the completion screen in the player leaves nothing for the next start`() {
        // AK-2: The user listened to the end, saw the completion screen and
        // tapped it away — it must not come back later.
        wiring.onMeditationFinish()

        wiring.onLeavePlayer()

        assertFalse(nextStartShowsCompletionScreen())
        assertTrue(didLeavePlayer, "Leaving must still navigate out of the player")
    }

    @Test
    fun `starting a new meditation drops a leftover marker`() {
        // AK-3
        wiring.onMeditationFinish()

        wiring.onMeditationLoad()

        assertFalse(nextStartShowsCompletionScreen())
    }

    @Test
    fun `an incoming file import drops a leftover marker`() {
        // The user listened to the end, then shared an MP3 into the app: the
        // app leaves for the import flow, so the completion screen is done.
        wiring.onMeditationFinish()

        wiring.onSessionInterrupted()

        assertFalse(nextStartShowsCompletionScreen())
    }

    @Test
    fun `an aborted meditation shows no completion screen on the next start`() {
        // Negative test: closing the player without a natural end.
        wiring.onLeavePlayer()

        assertFalse(nextStartShowsCompletionScreen())
    }
}
