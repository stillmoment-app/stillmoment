package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * The sage playhead grabber, rendered as a full-size overlay over the waveform and
 * positioned in the upper (playhead) touch zone (shared-108). The full-height playhead
 * line is drawn by [TrimWaveformView]; this is only the grip with its downward tip.
 *
 * Purely visual — the actual dragging is resolved geometrically by the single track gesture
 * ([TrimHitTesting]: the upper 45 % belongs to the playhead). An off-window playhead shows
 * no grip (never glued to the edge). 1:1 port of iOS `TrimPlayheadGrabber`.
 */
@Composable
fun TrimPlayheadGrabber(
    playheadTimeMs: Long,
    window: ClosedRange<Long>,
    trackWidthPx: Float,
    waveformHeightPx: Float,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val gradient = Brush.verticalGradient(listOf(theme.playheadAccentHi, theme.playheadAccent))
    Canvas(modifier = modifier.fillMaxSize()) {
        if (trackWidthPx <= 0f || !TrimGeometry.isTimeInWindow(playheadTimeMs, window)) {
            return@Canvas
        }
        val headX = TrimGeometry.x(playheadTimeMs, window, trackWidthPx)
        val zoneCenterY = waveformHeightPx * TrimHitTesting.VERTICAL_SPLIT / 2f
        drawGrabber(headX, zoneCenterY, gradient, theme.playheadAccent, theme.textOnPlayhead)
    }
}

private fun DrawScope.drawGrabber(
    headX: Float,
    zoneCenterY: Float,
    gradient: Brush,
    tipColor: Color,
    gripColor: Color
) {
    val grabberWidth = GRABBER_WIDTH_DP.dp.toPx()
    val grabberHeight = GRABBER_HEIGHT_DP.dp.toPx()
    val tipWidth = TIP_WIDTH_DP.dp.toPx()
    val tipHeight = TIP_HEIGHT_DP.dp.toPx()
    val totalHeight = grabberHeight + tipHeight
    val top = zoneCenterY - totalHeight / 2f

    drawRoundRect(
        brush = gradient,
        topLeft = Offset(headX - grabberWidth / 2f, top),
        size = Size(grabberWidth, grabberHeight),
        cornerRadius = CornerRadius(7.dp.toPx(), 7.dp.toPx())
    )

    // Two grip lines.
    val gripHeight = 9.dp.toPx()
    val gripWidth = 2.dp.toPx()
    val gripSpacing = 3.dp.toPx()
    val gripTop = top + grabberHeight / 2f - gripHeight / 2f
    listOf(headX - gripSpacing, headX + gripSpacing).forEach { gx ->
        drawRoundRect(
            color = gripColor.copy(alpha = 0.55f),
            topLeft = Offset(gx - gripWidth / 2f, gripTop),
            size = Size(gripWidth, gripHeight),
            cornerRadius = CornerRadius(gripWidth, gripWidth)
        )
    }

    // Downward-pointing tip below the grabber.
    val tipTop = top + grabberHeight
    val tipPath = Path().apply {
        moveTo(headX - tipWidth / 2f, tipTop)
        lineTo(headX + tipWidth / 2f, tipTop)
        lineTo(headX, tipTop + tipHeight)
        close()
    }
    drawPath(tipPath, color = tipColor)
}

private const val GRABBER_WIDTH_DP = 32f
private const val GRABBER_HEIGHT_DP = 20f
private const val TIP_WIDTH_DP = 10f
private const val TIP_HEIGHT_DP = 6f
