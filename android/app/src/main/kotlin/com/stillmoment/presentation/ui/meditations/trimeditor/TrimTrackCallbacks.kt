package com.stillmoment.presentation.ui.meditations.trimeditor

import com.stillmoment.domain.models.TrimPoint

/**
 * Intent callbacks the trim track ([TrimWaveformSection]) forwards to the ViewModel.
 * Bundled so the section/track composables stay below the parameter-count threshold.
 */
@androidx.compose.runtime.Immutable
data class TrimTrackCallbacks(
    val onMovePoint: (TrimPoint, Long) -> Unit,
    val onMarkDragEnded: () -> Unit,
    val onSeek: (Long) -> Unit,
    val onPlayheadDragEnded: () -> Unit,
    val onPanWindow: (Long) -> Unit,
    val onZoomOut: () -> Unit,
    val onFocusPoint: (TrimPoint) -> Unit
)
