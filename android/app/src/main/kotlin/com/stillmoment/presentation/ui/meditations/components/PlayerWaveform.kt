@file:Suppress("MatchingDeclarationName")

package com.stillmoment.presentation.ui.meditations.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
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
 * Scrub gesture callbacks for the waveform window (shared-109). Bundled so the composable's
 * parameter list stays small: grabbing pauses ([onStart]), each move scrubs to a range-relative
 * position ([onScrubTo]), releasing resumes ([onEnd]).
 */
@Immutable
data class PlayerScrubCallbacks(
    val onStart: () -> Unit,
    val onScrubTo: (Long) -> Unit,
    val onEnd: () -> Unit
)

/**
 * The window inputs for [PlayerWaveform] (shared-109). Bundled to keep the composable's
 * parameter list small. All positions are RANGE-RELATIVE ms (0 = trim start).
 *
 * @param positionMs Live range-relative position (drag position while dragging, else audio).
 * @param boundsMs Playable range `[0, effectiveDuration]`; bars/scrub stay inside it.
 * @param trackStartMs Absolute file time of position 0 (the trim start).
 * @param trackDurationMs Full file duration — maps sample index to file time.
 */
@Immutable
data class WaveformWindowSpec(
    val positionMs: Long,
    val boundsMs: LongRange,
    val trackStartMs: Long,
    val trackDurationMs: Long,
    val isPlaying: Boolean,
    val isDragging: Boolean
)

/**
 * The core of the waveform player: a ±30 s window of the meditation's waveform that scrolls
 * past a fixed, glowing "now"-line in the screen center (shared-109). Past audio (left of
 * center) is drawn in copper (`interactive`), upcoming audio (right) is a pale `textPrimary`.
 * Grabbing the band scrubs — the gesture pauses playback and resumes on release.
 *
 * 1:1 visual port of iOS `WaveformWindowView` (windowSec 60, height 188, barStep 3.2, barWidth
 * 2.0, maxHalfFactor 0.40, edge-fade 56). The scroll glides between the audio service's coarse
 * position updates by interpolating on each frame ([withFrameNanos]) while playing, anchored to
 * the true position so it recovers cleanly after a seek/background pause — the real audio
 * position stays the source of truth.
 *
 * The samples in [waveform] span the full file, so they are mapped through the trim start in
 * [spec] when drawn. See [WaveformWindowSpec] for the position/track inputs.
 */
@Composable
fun PlayerWaveform(
    waveform: MeditationWaveform?,
    waveformLoadFailed: Boolean,
    spec: WaveformWindowSpec,
    scrub: PlayerScrubCallbacks,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val nowMs = rememberInterpolatedNow(spec.positionMs, spec.boundsMs, spec.isPlaying, spec.isDragging)

    var widthPx by remember { mutableFloatStateOf(0f) }
    val currentPosition by rememberUpdatedState(spec.positionMs)
    val currentBounds by rememberUpdatedState(spec.boundsMs)
    val currentScrub by rememberUpdatedState(scrub)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(WINDOW_HEIGHT)
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragStart = { currentScrub.onStart() },
                    onDragEnd = { currentScrub.onEnd() },
                    onDragCancel = { currentScrub.onEnd() }
                ) { change, _ ->
                    change.consume()
                    val target = PlayheadWindowGeometry.msForX(
                        x = change.position.x,
                        nowMs = currentPosition,
                        windowSec = WINDOW_SEC,
                        width = widthPx
                    )
                    currentScrub.onScrubTo(target.coerceIn(currentBounds))
                }
            }
    ) {
        widthPx = size.width
        if (waveformLoadFailed || waveform == null) {
            drawFallbackBaseline(theme.textPrimary.copy(alpha = FALLBACK_ALPHA))
        } else {
            drawWindowBars(
                samples = waveform.samples,
                nowMs = nowMs,
                boundsMs = spec.boundsMs,
                trackStartMs = spec.trackStartMs,
                trackDurationMs = spec.trackDurationMs,
                pastColor = theme.interactive,
                futureColor = theme.textPrimary
            )
        }
        drawNowLine(theme.playGradientBot)
    }
}

/**
 * Drives a smooth `now` between the audio service's coarse 500 ms position ticks. While playing
 * and not dragging it advances by the per-frame wall-clock delta, re-anchoring to [positionMs]
 * only on a real jump (seek, drag end, background recovery) larger than [REANCHOR_THRESHOLD_MS]
 * — the 500 ms ticks arrive with jitter, so re-anchoring on every one would stutter. While
 * paused or dragging it simply follows [positionMs] (the source of truth).
 */
@Composable
private fun rememberInterpolatedNow(
    positionMs: Long,
    boundsMs: LongRange,
    isPlaying: Boolean,
    isDragging: Boolean
): Long {
    val smooth = isPlaying && !isDragging
    if (!smooth) {
        return positionMs
    }

    var visualNowMs by remember { mutableLongStateOf(positionMs) }
    val latestPosition by rememberUpdatedState(positionMs)
    val upperBound by rememberUpdatedState(boundsMs.last)

    LaunchedEffect(Unit) {
        var lastFrameNs = 0L
        visualNowMs = latestPosition
        while (true) {
            withFrameNanos { frameNs ->
                if (lastFrameNs == 0L) {
                    lastFrameNs = frameNs
                }
                val deltaMs = (frameNs - lastFrameNs) / 1_000_000L
                lastFrameNs = frameNs
                val advanced = visualNowMs + deltaMs
                // Snap back to the audio truth on a genuine jump; otherwise glide forward.
                visualNowMs = if (kotlin.math.abs(advanced - latestPosition) > REANCHOR_THRESHOLD_MS) {
                    latestPosition
                } else {
                    advanced
                }.coerceAtMost(upperBound)
            }
        }
    }
    return visualNowMs
}

private fun DrawScope.drawFallbackBaseline(color: Color) {
    val lineHeight = FALLBACK_LINE_DP.dp.toPx()
    drawRect(
        color = color,
        topLeft = Offset(0f, (size.height - lineHeight) / 2f),
        size = Size(size.width, lineHeight)
    )
}

private fun DrawScope.drawWindowBars(
    samples: List<Float>,
    nowMs: Long,
    boundsMs: LongRange,
    trackStartMs: Long,
    trackDurationMs: Long,
    pastColor: Color,
    futureColor: Color
) {
    if (samples.isEmpty() || trackDurationMs <= 0L || size.width <= 0f) {
        return
    }
    val density = PlayheadWindowGeometry.pxPerSec(WINDOW_SEC, size.width)
    if (density <= 0.0) {
        return
    }
    val secPerSample = trackDurationMs / 1000.0 / samples.size
    if (secPerSample <= 0.0) {
        return
    }

    // Each bar is a fixed sample whose x slides with `now`, so the band scrolls as one rigid
    // body. Bars are grouped into fixed global buckets so the on-screen density stays ~constant
    // across file lengths; bucket boundaries never shift while scrolling (no "jelly").
    val pxPerSample = secPerSample * density
    val step = maxOf(1, kotlin.math.ceil(BAR_STEP_PX / maxOf(pxPerSample, 0.0001)).toInt())
    val halfWindowSamples = kotlin.math.ceil(WINDOW_SEC / 2 / secPerSample).toInt() + step
    val nowFileSec = (trackStartMs + nowMs) / 1000.0
    val centerIndex = (nowFileSec / secPerSample).toInt()
    val firstIndex = maxOf(centerIndex - halfWindowSamples, 0)
    val lastIndex = minOf(centerIndex + halfWindowSamples, samples.size - 1)
    if (firstIndex > lastIndex) {
        return
    }

    val metrics = BarMetrics(
        nowMs = nowMs,
        center = size.width / 2f,
        density = density,
        cy = size.height / 2f,
        maxHalf = size.height * MAX_HALF_FACTOR,
        bounds = boundsMs,
        width = size.width,
        secPerSample = secPerSample,
        trackStartMs = trackStartMs
    )
    val barWidthPx = BAR_WIDTH_PX
    var bucketStart = firstIndex - (firstIndex % step)
    while (bucketStart <= lastIndex) {
        drawBar(bucketStart, samples, step, metrics, barWidthPx, pastColor, futureColor)
        bucketStart += step
    }
}

@Suppress("LongParameterList")
private fun DrawScope.drawBar(
    bucketStart: Int,
    samples: List<Float>,
    step: Int,
    metrics: BarMetrics,
    barWidthPx: Float,
    pastColor: Color,
    futureColor: Color
) {
    // Absolute file time of this bucket; range-relative time for bounds/past test.
    val fileSec = bucketStart * metrics.secPerSample
    val relativeMs = (fileSec * 1000.0).toLong() - metrics.trackStartMs
    if (relativeMs < metrics.bounds.first || relativeMs > metrics.bounds.last) {
        return
    }
    val positionX = metrics.center + ((relativeMs - metrics.nowMs) / 1000.0 * metrics.density).toFloat()
    val amp = peakAmplitude(samples, bucketStart, step)
    val half = maxOf(MIN_HALF_HEIGHT_PX, amp * metrics.maxHalf)
    val isPast = relativeMs <= metrics.nowMs
    val baseAlpha = if (isPast) PAST_BASE_ALPHA + PAST_AMP_ALPHA * amp else FUTURE_ALPHA
    val alpha = baseAlpha * edgeFade(positionX, metrics.width)
    if (alpha <= 0f) {
        return
    }
    val color = if (isPast) pastColor else futureColor
    drawRoundRect(
        color = color.copy(alpha = alpha),
        topLeft = Offset(positionX - barWidthPx / 2f, metrics.cy - half),
        size = Size(barWidthPx, half * 2f),
        cornerRadius = CornerRadius(barWidthPx / 2f, barWidthPx / 2f)
    )
}

/** Loudest sample in the fixed bucket — keeps short peaks visible when samples collapse. */
private fun peakAmplitude(samples: List<Float>, start: Int, step: Int): Float {
    val end = minOf(start + step, samples.size)
    var peak = 0f
    for (index in start until end) {
        if (samples[index] > peak) {
            peak = samples[index]
        }
    }
    return peak
}

/** Linear alpha ramp toward 0 within [EDGE_FADE_PX] of either edge. */
private fun edgeFade(positionX: Float, width: Float): Float {
    val leftFade = (positionX / EDGE_FADE_PX).coerceAtMost(1f)
    val rightFade = ((width - positionX) / EDGE_FADE_PX).coerceAtMost(1f)
    return maxOf(0f, minOf(leftFade, rightFade))
}

private fun DrawScope.drawNowLine(color: Color) {
    val lineWidth = NOW_LINE_WIDTH_PX
    drawRect(
        color = color,
        topLeft = Offset(size.width / 2f - lineWidth / 2f, 0f),
        size = Size(lineWidth, size.height)
    )
}

/** Per-frame render constants shared by every bar of one pass. */
private data class BarMetrics(
    val nowMs: Long,
    val center: Float,
    val density: Double,
    val cy: Float,
    val maxHalf: Float,
    val bounds: LongRange,
    val width: Float,
    val secPerSample: Double,
    val trackStartMs: Long
)

/** Visible window in seconds — ±30 s, matching iOS `windowSec`. */
const val WINDOW_SEC: Double = 60.0

/** Window height — matches iOS `windowHeight`. */
val WINDOW_HEIGHT: Dp = 188.dp

private const val BAR_STEP_PX = 3.2f
private const val BAR_WIDTH_PX = 2.0f
private const val MAX_HALF_FACTOR = 0.40f
private const val MIN_HALF_HEIGHT_PX = 0.8f
private const val EDGE_FADE_PX = 56f
private const val NOW_LINE_WIDTH_PX = 2f
private const val PAST_BASE_ALPHA = 0.55f
private const val PAST_AMP_ALPHA = 0.45f
private const val FUTURE_ALPHA = 0.16f
private const val FALLBACK_ALPHA = 0.16f
private const val FALLBACK_LINE_DP = 2f

/** Position jump (ms) above which the smooth scroll re-anchors to the true audio position. */
private const val REANCHOR_THRESHOLD_MS = 750L
