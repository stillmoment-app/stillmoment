package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * A single trim mark (start or end): a thin full-height cut edge plus a grip knob sitting
 * clearly in the lower half of the waveform (shared-107).
 *
 * Purely visual — it never participates in hit testing. Touches are resolved geometrically
 * by the single track gesture in [TrimWaveformSection] ([TrimHitTesting]), so overlapping
 * marks can never steal each other's touch. The active mark is wider and carries a glow ring.
 *
 * 1:1 port of iOS `TrimMarkHandle` (without the pulse animation — kept static for simplicity;
 * the active mark is still emphasised by width + glow). Drawn as a full-size overlay over the
 * waveform; positions itself at [timeMs] inside [window].
 */
@Composable
fun TrimMarkHandle(
    timeMs: Long,
    isActive: Boolean,
    trackWidthPx: Float,
    window: ClosedRange<Long>,
    waveformHeightPx: Float,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val gradient = Brush.verticalGradient(listOf(theme.playGradientTop, theme.playGradientBot))
    Box(modifier = modifier.fillMaxSize()) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            if (trackWidthPx <= 0f) {
                return@Canvas
            }
            val markX = TrimGeometry.x(timeMs, window, trackWidthPx)
            drawCutEdge(markX, isActive, gradient)
            drawKnob(markX, waveformHeightPx, isActive, gradient, theme.interactive, theme.textOnInteractive)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawCutEdge(
    markX: Float,
    isActive: Boolean,
    gradient: Brush
) {
    val edgeWidth = (if (isActive) 4f else 3f).dp.toPx()
    val corner = CornerRadius(3.dp.toPx(), 3.dp.toPx())
    drawRoundRect(
        brush = gradient,
        topLeft = Offset(markX - edgeWidth / 2f, 0f),
        size = Size(edgeWidth, size.height),
        cornerRadius = corner,
        alpha = if (isActive) 1f else 0.7f
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawKnob(
    markX: Float,
    waveformHeightPx: Float,
    isActive: Boolean,
    gradient: Brush,
    glowColor: Color,
    gripColor: Color
) {
    val knobWidth = (if (isActive) 20f else 16f).dp.toPx()
    val knobHeight = (if (isActive) 44f else 38f).dp.toPx()
    val knobCenterY = waveformHeightPx * KNOB_CENTER_FRACTION
    val topLeft = Offset(markX - knobWidth / 2f, knobCenterY - knobHeight / 2f)
    val corner = CornerRadius(8.dp.toPx(), 8.dp.toPx())

    if (isActive) {
        drawRoundRect(
            color = glowColor.copy(alpha = 0.35f),
            topLeft = Offset(topLeft.x - 2.dp.toPx(), topLeft.y - 2.dp.toPx()),
            size = Size(knobWidth + 4.dp.toPx(), knobHeight + 4.dp.toPx()),
            cornerRadius = corner,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2.dp.toPx())
        )
    }
    drawRoundRect(brush = gradient, topLeft = topLeft, size = Size(knobWidth, knobHeight), cornerRadius = corner)

    // Two grip lines.
    val gripHeight = 13.dp.toPx()
    val gripWidth = 2.dp.toPx()
    val gripSpacing = 3.dp.toPx()
    val gripTop = knobCenterY - gripHeight / 2f
    listOf(markX - gripSpacing, markX + gripSpacing).forEach { gx ->
        drawRoundRect(
            color = gripColor.copy(alpha = 0.5f),
            topLeft = Offset(gx - gripWidth / 2f, gripTop),
            size = Size(gripWidth, gripHeight),
            cornerRadius = CornerRadius(gripWidth, gripWidth)
        )
    }
}

/** Vertical center of the knob as a fraction of the waveform height — in the lower (mark) zone. */
private const val KNOB_CENTER_FRACTION = 0.74f
