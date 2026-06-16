package com.stillmoment.presentation.ui.meditations.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * A compressed overview of the whole (trimmed) track below the scrolling window (shared-109).
 * Shows the overall position the ±30 s window can't: the played portion in copper, the rest
 * pale. Tapping or dragging it is an absolute seek (fraction `p` → `p · effectiveDuration`,
 * range-relative).
 *
 * 1:1 visual port of iOS `WaveformMiniOverview` (height 30, 160 AVERAGED bars). Averaging keeps
 * the energy envelope so speech pauses show up as valleys instead of every bar filling up.
 *
 * @param waveform Full-file waveform; the trimmed slice is averaged to [DISPLAY_BAR_COUNT].
 * @param progress Played fraction of the trimmed track (0…1) — also the marker position.
 * @param trimStartFraction `effectiveStart / fileDuration`; left edge of the audible slice.
 * @param trimEndFraction `effectiveEnd / fileDuration`; right edge of the audible slice.
 * @param onSeekToFraction Absolute seek; the fraction is range-relative to the trimmed track.
 */
@Composable
fun PlayerTrackOverview(
    waveform: MeditationWaveform?,
    waveformLoadFailed: Boolean,
    progress: Float,
    trimStartFraction: Double,
    trimEndFraction: Double,
    onSeekToFraction: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    var widthPx by remember { mutableFloatStateOf(0f) }
    val currentSeek by rememberUpdatedState(onSeekToFraction)

    val played = theme.interactive.copy(alpha = PLAYED_ALPHA)
    val remaining = theme.textPrimary.copy(alpha = REMAINING_ALPHA)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(OVERVIEW_HEIGHT)
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    if (widthPx > 0f) {
                        currentSeek((offset.x / widthPx).coerceIn(0f, 1f))
                    }
                }
            }
            .pointerInput(Unit) {
                detectHorizontalDragGestures { change, _ ->
                    change.consume()
                    if (widthPx > 0f) {
                        currentSeek((change.position.x / widthPx).coerceIn(0f, 1f))
                    }
                }
            }
    ) {
        widthPx = size.width
        if (waveformLoadFailed || waveform == null) {
            drawFallbackTrack(progress, theme.interactive.copy(alpha = PLAYED_ALPHA), remaining)
        } else {
            val samples = averagedTrimmedSamples(waveform, trimStartFraction, trimEndFraction)
            drawOverviewBars(samples, progress, played, remaining)
        }
        drawMarker(progress, theme.playGradientBot)
    }
}

/** Slices the trimmed range out of the full waveform and averages it to [DISPLAY_BAR_COUNT]. */
private fun averagedTrimmedSamples(
    waveform: MeditationWaveform,
    trimStartFraction: Double,
    trimEndFraction: Double
): List<Float> {
    val trimmed = waveform.windowed(trimStartFraction, trimEndFraction).samples
    return averaged(trimmed, DISPLAY_BAR_COUNT)
}

/** Reduces [samples] to [count] bars by AVERAGE (energy envelope), preserving pauses. */
private fun averaged(samples: List<Float>, count: Int): List<Float> {
    if (count <= 0 || samples.size <= count) {
        return samples
    }
    return List(count) { bucket ->
        val start = bucket * samples.size / count
        val end = maxOf(start + 1, (bucket + 1) * samples.size / count).coerceAtMost(samples.size)
        var sum = 0f
        for (index in start until end) {
            sum += samples[index]
        }
        sum / (end - start)
    }
}

private fun DrawScope.drawOverviewBars(samples: List<Float>, progress: Float, played: Color, remaining: Color) {
    if (samples.isEmpty()) {
        return
    }
    val count = samples.size
    val gapPx = BAR_GAP_DP.dp.toPx()
    val totalGap = gapPx * (count - 1)
    val barWidth = ((size.width - totalGap) / count).coerceAtLeast(MIN_BAR_WIDTH_PX)
    val minBarHeight = MIN_BAR_HEIGHT_DP.dp.toPx()
    val playedX = size.width * progress.coerceIn(0f, 1f)

    samples.forEachIndexed { index, sample ->
        val positionX = index * (barWidth + gapPx)
        val barHeight = (sample * size.height).coerceAtLeast(minBarHeight)
        val positionY = (size.height - barHeight) / 2f
        val color = if (positionX <= playedX) played else remaining
        drawRect(color = color, topLeft = Offset(positionX, positionY), size = Size(barWidth, barHeight))
    }
}

private fun DrawScope.drawFallbackTrack(progress: Float, played: Color, remaining: Color) {
    val lineHeight = FALLBACK_LINE_DP.dp.toPx()
    val y = (size.height - lineHeight) / 2f
    drawRect(color = remaining, topLeft = Offset(0f, y), size = Size(size.width, lineHeight))
    drawRect(
        color = played,
        topLeft = Offset(0f, y),
        size = Size(size.width * progress.coerceIn(0f, 1f), lineHeight)
    )
}

private fun DrawScope.drawMarker(progress: Float, color: Color) {
    val lineWidth = MARKER_WIDTH_PX
    val x = size.width * progress.coerceIn(0f, 1f) - lineWidth / 2f
    drawRect(color = color, topLeft = Offset(x, 0f), size = Size(lineWidth, size.height))
}

/** Mini-overview height — matches iOS `height`. */
val OVERVIEW_HEIGHT: Dp = 30.dp

/** Overview bars — matches iOS `displayBarCount` (averaged). */
const val DISPLAY_BAR_COUNT = 160

private const val PLAYED_ALPHA = 0.85f
private const val REMAINING_ALPHA = 0.14f
private const val BAR_GAP_DP = 1f
private const val MIN_BAR_HEIGHT_DP = 2f
private const val MIN_BAR_WIDTH_PX = 0.5f
private const val MARKER_WIDTH_PX = 2f
private const val FALLBACK_LINE_DP = 3f
