package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for [CompletionOverlayViewModel].
 *
 * The marker is the persistence mechanism for shared-080: it ensures the
 * "thank you" screen still appears when the user re-opens the app after
 * a guided meditation finished naturally and the OS terminated the app
 * while the screen was locked.
 *
 * `SavedStateHandle` is the activity-scoped equivalent of iOS `@SceneStorage`:
 * it survives system-initiated process death (the relevant case here) and
 * is cleared by user-initiated swipe-to-kill.
 */
class CompletionOverlayViewModelTest {

    @Test
    fun `marker is not initially set on a fresh launch`() {
        // Empty handle == fresh launch, no prior meditation completion.
        val viewModel = CompletionOverlayViewModel(SavedStateHandle())

        assertFalse(viewModel.isMarkerSetInitially)
    }

    @Test
    fun `marker is initially set after setMarker survived process death`() {
        // First instance: meditation finished naturally and persisted the marker.
        val savedStateHandle = SavedStateHandle()
        CompletionOverlayViewModel(savedStateHandle).setMarker()

        // Reusing the same SavedStateHandle simulates a process-death-restore:
        // the system handed our previously-persisted state back to a new ViewModel.
        val restored = CompletionOverlayViewModel(savedStateHandle)

        assertTrue(restored.isMarkerSetInitially)
    }

    @Test
    fun `marker is not initially set after clearMarker survived process death`() {
        val savedStateHandle = SavedStateHandle()
        val viewModel = CompletionOverlayViewModel(savedStateHandle)
        viewModel.setMarker()
        viewModel.clearMarker()

        val restored = CompletionOverlayViewModel(savedStateHandle)

        assertFalse(restored.isMarkerSetInitially)
    }

    @Test
    fun `marker is not initially set when no meditation has ever finished`() {
        // Cold start, never any persistence — same shape as the first test
        // but separately documents the "negative test" case.
        val restored = CompletionOverlayViewModel(SavedStateHandle())

        assertFalse(restored.isMarkerSetInitially)
    }

    @Test
    fun `isMarkerSetInitially is frozen and not affected by subsequent setMarker calls`() {
        // Simulates AK-6 (shared-080): player finishes naturally during an active session.
        // The overlay must NOT flip on mid-session — it is only meant for cold-start restores.
        //
        // On the composable side this is guaranteed by `remember { mutableStateOf(isMarkerSetInitially) }`.
        // This test verifies the contract of isMarkerSetInitially itself: it is a snapshot
        // taken at construction time and never changes, so the composable's remember() stays stable.
        val savedStateHandle = SavedStateHandle() // app started without a prior marker
        val viewModel = CompletionOverlayViewModel(savedStateHandle)
        assertFalse(viewModel.isMarkerSetInitially)

        // Player signals natural end while the session is active
        viewModel.setMarker()

        // isMarkerSetInitially must remain false — it captured the state at app start
        assertFalse(viewModel.isMarkerSetInitially)
    }
}
