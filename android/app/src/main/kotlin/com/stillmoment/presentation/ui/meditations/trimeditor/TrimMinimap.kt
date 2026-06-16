package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Thin whole-file strip shown above the track while zoomed (shared-108): range fill
 * between the marks, two mark ticks, a playhead tick, and a sage frame at the window's
 * position. Tapping or dragging pans the zoom window ([onPan] receives the new center
 * time in ms).
 *
 * 1:1 port of iOS `TrimMinimapView`. All time→x mappings use the WHOLE file as the
 * window (`0..duration`), since the minimap always shows the full file.
 */
@Composable
fun TrimMinimap(
    startMs: Long,
    endMs: Long,
    playheadTimeMs: Long,
    window: ClosedRange<Long>,
    durationMs: Long,
    onPan: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val fullFile = 0L..durationMs.coerceAtLeast(0L)
    val label = stringResource(R.string.trim_editor_a11y_minimap)
    val currentOnPan by rememberUpdatedState(onPan)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(MINIMAP_HEIGHT_DP.dp)
            .semantics { contentDescription = label }
            .pointerInput(durationMs) {
                detectTapGestures { offset ->
                    currentOnPan(TrimGeometry.time(offset.x, fullFile, size.width.toFloat()))
                }
            }
            .pointerInput(durationMs) {
                detectDragGestures { change, _ ->
                    currentOnPan(TrimGeometry.time(change.position.x, fullFile, size.width.toFloat()))
                }
            }
    ) {
        drawMinimapBackground(theme.cardBackground, theme.cardBorder)
        drawRangeFill(startMs, endMs, fullFile, theme.interactive.copy(alpha = RANGE_FILL_ALPHA))
        drawTick(startMs, fullFile, theme.interactive)
        drawTick(endMs, fullFile, theme.interactive)
        drawTick(playheadTimeMs, fullFile, theme.playheadAccentHi)
        drawWindowFrame(window, fullFile, theme.playheadAccent.copy(alpha = WINDOW_FILL_ALPHA), theme.playheadAccentHi)
    }
}

private fun DrawScope.drawMinimapBackground(fill: Color, border: Color) {
    val corner = CornerRadius(BG_CORNER_DP.dp.toPx(), BG_CORNER_DP.dp.toPx())
    drawRoundRect(color = fill, size = size, cornerRadius = corner)
    drawRoundRect(color = border, size = size, cornerRadius = corner, style = Stroke(width = 1.dp.toPx()))
}

private fun DrawScope.drawRangeFill(startMs: Long, endMs: Long, fullFile: ClosedRange<Long>, color: Color) {
    val startX = TrimGeometry.x(startMs, fullFile, size.width)
    val endX = TrimGeometry.x(endMs, fullFile, size.width)
    drawRect(color = color, topLeft = Offset(startX, 0f), size = Size((endX - startX).coerceAtLeast(0f), size.height))
}

private fun DrawScope.drawTick(timeMs: Long, fullFile: ClosedRange<Long>, color: Color) {
    val x = TrimGeometry.x(timeMs, fullFile, size.width)
    val tickWidth = 2.dp.toPx()
    val verticalPad = 2.dp.toPx()
    drawRect(
        color = color,
        topLeft = Offset(x - tickWidth / 2f, verticalPad),
        size = Size(tickWidth, size.height - verticalPad * 2f)
    )
}

private fun DrawScope.drawWindowFrame(
    window: ClosedRange<Long>,
    fullFile: ClosedRange<Long>,
    fill: Color,
    border: Color
) {
    val lowerX = TrimGeometry.x(window.start, fullFile, size.width)
    val upperX = TrimGeometry.x(window.endInclusive, fullFile, size.width)
    val width = (upperX - lowerX).coerceAtLeast(0f)
    val corner = CornerRadius(FRAME_CORNER_DP.dp.toPx(), FRAME_CORNER_DP.dp.toPx())
    val verticalPad = 1.dp.toPx()
    drawRoundRect(
        color = fill,
        topLeft = Offset(lowerX, verticalPad),
        size = Size(width, size.height - verticalPad * 2f),
        cornerRadius = corner
    )
    drawRoundRect(
        color = border,
        topLeft = Offset(lowerX, verticalPad),
        size = Size(width, size.height - verticalPad * 2f),
        cornerRadius = corner,
        style = Stroke(width = 1.5.dp.toPx())
    )
}

private const val MINIMAP_HEIGHT_DP = 26f
private const val RANGE_FILL_ALPHA = 0.20f
private const val WINDOW_FILL_ALPHA = 0.12f
private const val BG_CORNER_DP = 8f
private const val FRAME_CORNER_DP = 6f
