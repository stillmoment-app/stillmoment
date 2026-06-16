package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Draws the waveform of the trim editor, downsampled to [DISPLAY_BAR_COUNT] display bars
 * (shared-107/108).
 *
 * The cached waveform carries [MeditationWaveform.SAMPLE_COUNT] peaks (high resolution for
 * the zoom); this overview reduces them peak-preservingly. Bars inside `[start, end]` use
 * the accent (interactive) colour, bars outside are dimmed. A range-highlight box marks the
 * selection and a playhead line is drawn while audio plays/previews. When decoding failed,
 * a single flat baseline is drawn instead — the editor stays fully functional.
 *
 * 1:1 port of iOS `TrimWaveformView`. Times are ms (Long).
 *
 * @param window Visible time window (zoom); the whole file in the overview / mini card.
 * @param playheadTimeMs null hides the playhead (mini card variant passes null).
 */
@Composable
fun TrimWaveformView(
    spec: TrimWaveformSpec,
    isLoading: Boolean,
    loadFailed: Boolean,
    modifier: Modifier = Modifier,
    height: Dp = DEFAULT_HEIGHT
) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center
    ) {
        if (loadFailed) {
            FallbackLine(color = theme.controlTrack)
        } else {
            WaveformCanvas(spec = spec, palette = WaveformPalette.from(theme), isLoading = isLoading)
            if (isLoading) {
                CircularProgressIndicator(color = theme.interactive)
            }
        }
    }
}

/**
 * The geometry the waveform renders: the waveform data, the file duration, the selected
 * range, the optional playhead and the visible window. Bundled to keep param counts sane.
 */
@androidx.compose.runtime.Immutable
data class TrimWaveformSpec(
    val waveform: MeditationWaveform?,
    val durationMs: Long,
    val startMs: Long,
    val endMs: Long,
    val playheadTimeMs: Long?,
    val window: ClosedRange<Long>,
    val barCount: Int = DISPLAY_BAR_COUNT
)

/** Resolved colours for the waveform — pulled once from the theme. */
private data class WaveformPalette(
    val inAccent: Color,
    val dimmed: Color,
    val rangeFill: Color,
    val rangeBorder: Color,
    val playheadColor: Color
) {
    companion object {
        fun from(theme: com.stillmoment.presentation.ui.theme.StillMomentColors) = WaveformPalette(
            inAccent = theme.interactive,
            dimmed = theme.textPrimary.copy(alpha = DIMMED_ALPHA),
            rangeFill = theme.interactive.copy(alpha = RANGE_FILL_ALPHA),
            rangeBorder = theme.interactive.copy(alpha = RANGE_BORDER_ALPHA),
            playheadColor = theme.playheadAccentHi
        )
    }
}

@Composable
private fun FallbackLine(color: Color) {
    Canvas(modifier = Modifier.fillMaxWidth().height(2.dp)) {
        drawRect(color = color, size = Size(size.width, size.height))
    }
}

@Composable
private fun WaveformCanvas(spec: TrimWaveformSpec, palette: WaveformPalette, isLoading: Boolean) {
    Canvas(
        modifier = Modifier
            .fillMaxSize()
            .alpha(if (isLoading) LOADING_ALPHA else 1f)
    ) {
        if (spec.durationMs <= 0L) {
            return@Canvas
        }
        drawRangeHighlight(spec, palette.rangeFill, palette.rangeBorder)
        drawBars(spec, palette.inAccent, palette.dimmed)
        spec.playheadTimeMs?.let { drawPlayhead(it, spec.window, palette.playheadColor) }
    }
}

private fun DrawScope.drawBars(spec: TrimWaveformSpec, inAccent: Color, dimmed: Color) {
    val window = spec.window
    val span = window.endInclusive - window.start
    if (span <= 0L) {
        return
    }
    val samples = spec.waveform
        ?.windowed(window.start.toDouble() / spec.durationMs, window.endInclusive.toDouble() / spec.durationMs)
        ?.downsampled(spec.barCount)
        ?.samples
        .orEmpty()
    if (samples.isEmpty()) {
        return
    }
    val count = samples.size
    val gapPx = BAR_GAP_DP.dp.toPx()
    val totalGap = gapPx * (count - 1)
    val barWidth = ((size.width - totalGap) / count).coerceAtLeast(MIN_BAR_WIDTH_PX)
    val minBarHeight = MIN_BAR_HEIGHT_DP.dp.toPx()
    val cornerPx = BAR_CORNER_DP.dp.toPx()

    samples.forEachIndexed { index, sample ->
        val positionX = index * (barWidth + gapPx)
        val barHeight = (sample * size.height).coerceAtLeast(minBarHeight)
        val positionY = (size.height - barHeight) / 2f
        val barTime = window.start + (span * (index.toDouble() / count)).toLong()
        val isInRange = barTime in spec.startMs..spec.endMs
        drawRoundRect(
            color = if (isInRange) inAccent else dimmed,
            topLeft = Offset(positionX, positionY),
            size = Size(barWidth, barHeight),
            cornerRadius = CornerRadius(cornerPx, cornerPx)
        )
    }
}

private fun DrawScope.drawRangeHighlight(spec: TrimWaveformSpec, fill: Color, border: Color) {
    val startX = TrimGeometry.x(spec.startMs, spec.window, size.width)
    val endX = TrimGeometry.x(spec.endMs, spec.window, size.width)
    val rectWidth = (endX - startX).coerceAtLeast(0f)
    if (rectWidth <= 0f) {
        return
    }
    val cornerPx = RANGE_CORNER_DP.dp.toPx()
    drawRoundRect(
        color = fill,
        topLeft = Offset(startX, 0f),
        size = Size(rectWidth, size.height),
        cornerRadius = CornerRadius(cornerPx, cornerPx)
    )
    drawRoundRect(
        color = border,
        topLeft = Offset(startX, 0f),
        size = Size(rectWidth, size.height),
        cornerRadius = CornerRadius(cornerPx, cornerPx),
        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 1.dp.toPx())
    )
}

private fun DrawScope.drawPlayhead(playheadTimeMs: Long, window: ClosedRange<Long>, color: Color) {
    if (!TrimGeometry.isTimeInWindow(playheadTimeMs, window)) {
        return
    }
    val positionX = TrimGeometry.x(playheadTimeMs, window, size.width)
    val lineWidth = 2.dp.toPx()
    drawRect(
        color = color,
        topLeft = Offset(positionX - lineWidth / 2f, 0f),
        size = Size(lineWidth, size.height)
    )
}

/** Default rendered height; the mini card variant passes [MINI_HEIGHT]. */
val DEFAULT_HEIGHT: Dp = 108.dp

/** Mini-waveform height used inside the playback-range card. */
val MINI_HEIGHT: Dp = 44.dp

/** Display bars for the editor track — matches iOS exactly (cross-platform resolution). */
const val DISPLAY_BAR_COUNT = 220

/** Bars for the mini waveform inside the card — matches iOS (160, averaged). */
const val MINI_BAR_COUNT = 160

private const val DIMMED_ALPHA = 0.30f
private const val RANGE_FILL_ALPHA = 0.12f
private const val RANGE_BORDER_ALPHA = 0.35f
private const val LOADING_ALPHA = 0.35f
private const val BAR_GAP_DP = 1f
private const val BAR_CORNER_DP = 2f
private const val RANGE_CORNER_DP = 4f
private const val MIN_BAR_HEIGHT_DP = 2f
private const val MIN_BAR_WIDTH_PX = 0.5f
