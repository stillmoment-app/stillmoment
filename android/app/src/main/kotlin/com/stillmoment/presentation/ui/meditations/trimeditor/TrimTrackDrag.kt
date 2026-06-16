package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.input.pointer.PointerInputScope
import com.stillmoment.presentation.viewmodel.TrimEditorUiState

/**
 * The single, geometric drag loop of the trim track (shared-107). One pointer-down is
 * resolved once via [TrimHitTesting] (playhead vs. start/end mark), then every move is
 * mapped through the visible window and forwarded as a move/seek. On release the matching
 * "drag ended" intent fires so the ViewModel can audition the cut or start playback.
 *
 * Mirrors iOS `TrimWaveformSection.trackGesture` (a single `DragGesture(minimumDistance: 0)`
 * whose target is fixed at finger-down). [stateProvider]/[callbacksProvider] read the latest
 * state each event so the frozen-closure pitfall (android-078) does not bite.
 */
internal suspend fun PointerInputScope.trackDragLoop(
    grabRadiusPx: Float,
    waveformHeightPx: Float,
    stateProvider: () -> TrimEditorUiState,
    callbacksProvider: () -> TrimTrackCallbacks
) {
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = false)
        val width = size.width.toFloat()
        if (width <= 0f) {
            return@awaitEachGesture
        }
        val uiState = stateProvider()
        val state = uiState.editorState
        val window = uiState.window

        val session = TrimHitTesting.beginDrag(
            touchX = down.position.x,
            touchY = down.position.y,
            geometry = TrimTrackGeometry(
                waveformHeight = waveformHeightPx,
                headX = TrimGeometry.unclampedX(uiState.playheadTimeMs, window, width),
                startX = TrimGeometry.unclampedX(state.start, window, width),
                endX = TrimGeometry.unclampedX(state.end, window, width)
            ),
            activePoint = state.activePoint,
            grabRadiusPx = grabRadiusPx
        )

        applyDrag(session, down.position.x, window, width, callbacksProvider)
        down.consume()

        var pressed = true
        while (pressed) {
            val event = awaitPointerEvent()
            event.changes.forEach { change ->
                if (change.pressed) {
                    applyDrag(session, change.position.x, stateProvider().window, width, callbacksProvider)
                    change.consume()
                }
            }
            pressed = event.changes.any { it.pressed }
        }

        when (session.target) {
            is TrimDragTarget.Playhead -> callbacksProvider().onPlayheadDragEnded()
            is TrimDragTarget.Mark -> callbacksProvider().onMarkDragEnded()
        }
    }
}

private fun applyDrag(
    session: TrimDragSession,
    locationX: Float,
    window: ClosedRange<Long>,
    width: Float,
    callbacksProvider: () -> TrimTrackCallbacks
) {
    val time = TrimGeometry.time(locationX + session.offset, window, width)
    when (val target = session.target) {
        is TrimDragTarget.Playhead -> callbacksProvider().onSeek(time)
        is TrimDragTarget.Mark -> callbacksProvider().onMovePoint(target.point, time)
    }
}
