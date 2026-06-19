package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.systemGestureExclusion
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ZoomOut
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.TrimPoint
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.TrimEditorUiState

/**
 * The interactive trim track (shared-107/108): one waveform, visually split like its touch
 * zones — the sage playhead grabber lives in the upper zone, the copper trim marks in the
 * lower zone — with axis labels underneath. While zoomed, a whole-file minimap plus the
 * "Ganze Datei" zoom-out chip appear above the track.
 *
 * One single drag gesture covers the waveform and resolves geometrically (via [TrimHitTesting])
 * what the finger acts on: the upper 45 % moves the playhead, the lower zone moves a mark (in
 * clusters the active mark always wins). 1:1 port of iOS `TrimWaveformSection`.
 */
@Composable
fun TrimWaveformSection(uiState: TrimEditorUiState, callbacks: TrimTrackCallbacks, modifier: Modifier = Modifier) {
    val window = uiState.window
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (uiState.isZoomed) {
            ZoomedMinimapRow(uiState = uiState, onPanWindow = callbacks.onPanWindow, onZoomOut = callbacks.onZoomOut)
        }
        TrimTrack(uiState = uiState, callbacks = callbacks)
        AxisLabels(
            lowerMs = window.start,
            playheadMs = uiState.playheadTimeMs,
            upperMs = window.endInclusive,
            highlightPlayhead = uiState.isPlaying || uiState.isPreviewing
        )
    }
}

@Composable
private fun ZoomedMinimapRow(uiState: TrimEditorUiState, onPanWindow: (Long) -> Unit, onZoomOut: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        TrimMinimap(
            startMs = uiState.editorState.start,
            endMs = uiState.editorState.end,
            playheadTimeMs = uiState.playheadTimeMs,
            window = uiState.window,
            durationMs = uiState.editorState.duration,
            onPan = onPanWindow,
            modifier = Modifier.weight(1f)
        )
        ZoomOutChip(onZoomOut = onZoomOut)
    }
}

@Composable
private fun ZoomOutChip(onZoomOut: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val label = stringResource(R.string.trim_editor_a11y_zoom_out)
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(theme.cardBackground)
            .border(1.dp, theme.cardBorder, CircleShape)
            .clickable { onZoomOut() }
            .padding(horizontal = 11.dp, vertical = 5.dp)
            .semantics { contentDescription = label }
            .testTag("trimEditor.zoomOut"),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Filled.ZoomOut, contentDescription = null, tint = theme.textPrimary)
        Text(
            text = stringResource(R.string.trim_editor_zoom_out),
            style = TextStyle.caption.toComposeTextStyle(),
            color = theme.textPrimary
        )
    }
}

@Composable
private fun TrimTrack(uiState: TrimEditorUiState, callbacks: TrimTrackCallbacks) {
    var trackWidthPx by remember { mutableFloatStateOf(0f) }
    val density = LocalDensity.current
    val waveformHeightPx = with(density) { DEFAULT_HEIGHT.toPx() }
    val grabRadiusPx = with(density) { TrimHitTesting.GRAB_RADIUS_DP.dp.toPx() }
    val state = uiState.editorState
    val currentCallbacks by rememberUpdatedState(callbacks)
    val currentUiState by rememberUpdatedState(uiState)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(DEFAULT_HEIGHT)
            // The start mark sits near the left screen edge; without this Android claims an
            // edge-drag as the system back gesture and pops the editor mid-drag. 108dp is below
            // the 200dp-per-edge exclusion cap, so the whole track is reserved for our gestures.
            .systemGestureExclusion()
            .onSizeChanged { trackWidthPx = it.width.toFloat() }
            .pointerInput(Unit) {
                trackDragLoop(
                    grabRadiusPx = grabRadiusPx,
                    waveformHeightPx = waveformHeightPx,
                    stateProvider = { currentUiState },
                    callbacksProvider = { currentCallbacks }
                )
            }
            .testTag("trimEditor.track")
    ) {
        TrimWaveformView(
            spec = TrimWaveformSpec(
                waveform = uiState.waveform,
                durationMs = state.duration,
                startMs = state.start,
                endMs = state.end,
                playheadTimeMs = uiState.playheadTimeMs,
                window = uiState.window
            ),
            isLoading = uiState.isLoadingWaveform,
            loadFailed = uiState.waveformLoadFailed
        )
        TrackOverlays(uiState = uiState, trackWidthPx = trackWidthPx, waveformHeightPx = waveformHeightPx)
        EdgeChips(uiState = uiState, onFocusPoint = callbacks.onFocusPoint)
    }
}

@Composable
private fun TrimMarkIfVisible(
    timeMs: Long,
    isActive: Boolean,
    trackWidthPx: Float,
    window: ClosedRange<Long>,
    heightPx: Float
) {
    if (TrimGeometry.isTimeInWindow(timeMs, window)) {
        TrimMarkHandle(
            timeMs = timeMs,
            isActive = isActive,
            trackWidthPx = trackWidthPx,
            window = window,
            waveformHeightPx = heightPx
        )
    }
}

@Composable
private fun TrackOverlays(uiState: TrimEditorUiState, trackWidthPx: Float, waveformHeightPx: Float) {
    val state = uiState.editorState
    val window = uiState.window
    TrimPlayheadGrabber(
        playheadTimeMs = uiState.playheadTimeMs,
        window = window,
        trackWidthPx = trackWidthPx,
        waveformHeightPx = waveformHeightPx
    )
    TrimMarkIfVisible(state.start, state.activePoint == TrimPoint.START, trackWidthPx, window, waveformHeightPx)
    TrimMarkIfVisible(state.end, state.activePoint == TrimPoint.END, trackWidthPx, window, waveformHeightPx)
}

@Composable
private fun BoxScope.EdgeChips(uiState: TrimEditorUiState, onFocusPoint: (TrimPoint) -> Unit) {
    val state = uiState.editorState
    val window = uiState.window
    listOf(TrimPoint.START to state.start, TrimPoint.END to state.end).forEach { (point, time) ->
        if (!TrimGeometry.isTimeInWindow(time, window)) {
            val leading = time < window.start
            TrimEdgeChip(
                point = point,
                timeMs = time,
                pointsLeading = leading,
                onTap = { onFocusPoint(point) },
                modifier = Modifier
                    .align(if (leading) Alignment.CenterStart else Alignment.CenterEnd)
                    .padding(horizontal = 4.dp)
            )
        }
    }
}

@Composable
private fun AxisLabels(lowerMs: Long, playheadMs: Long, upperMs: Long, highlightPlayhead: Boolean) {
    val theme = LocalStillMomentColors.current
    val secondary = theme.textPrimary.copy(alpha = 0.6f)
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(formatTrimTime(lowerMs), style = TextStyle.micro.toComposeTextStyle(), color = secondary)
        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
            Text(
                formatTrimTime(playheadMs),
                style = TextStyle.micro.toComposeTextStyle(),
                color = if (highlightPlayhead) theme.playheadAccent else secondary
            )
        }
        Text(formatTrimTime(upperMs), style = TextStyle.micro.toComposeTextStyle(), color = secondary)
    }
}
