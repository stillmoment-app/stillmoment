package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Calm meditative loader: a pulsing copper core orbited by 5 dots on two orbital paths.
 *
 * Used by [DownloadProgressModal]. The animation is driven by a single
 * [withFrameMillis] loop that pauses when [isActive] is false, so the loader
 * stops consuming CPU when the app moves to the background.
 *
 * Geometry follows the design handoff in
 * `handoffs/design_handoff_download_animation/README.md`.
 */
@Composable
fun ConstellationLoader(color: Color, modifier: Modifier = Modifier, isActive: Boolean = true) {
    var elapsedMs by remember { mutableLongStateOf(0L) }

    LaunchedEffect(isActive) {
        if (!isActive) return@LaunchedEffect
        var lastFrameMs = withFrameMillis { it }
        while (true) {
            val now = withFrameMillis { it }
            elapsedMs += now - lastFrameMs
            lastFrameMs = now
        }
    }

    Canvas(modifier = modifier.size(CONTAINER_SIZE_DP.dp)) {
        val center = Offset(size.width / 2f, size.height / 2f)
        val tSeconds = elapsedMs / 1000.0

        drawBreathingCore(center = center, tSeconds = tSeconds, color = color)

        ORBITS.forEach { orbit ->
            drawOrbitalDot(center = center, orbit = orbit, tSeconds = tSeconds, color = color)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawBreathingCore(
    center: Offset,
    tSeconds: Double,
    color: Color
) {
    // Sinus oscillation between 0..1 with 4.2s cycle (period). Eased via raised sine
    // for a soft inhale/exhale feel close to easeInOut + autoreverse.
    val raw = (sin(2 * PI * tSeconds / CORE_CYCLE_SECONDS - PI / 2) + 1) / 2
    val scale = (CORE_SCALE_MIN + (CORE_SCALE_MAX - CORE_SCALE_MIN) * raw).toFloat()
    val alpha = (CORE_ALPHA_MIN + (CORE_ALPHA_MAX - CORE_ALPHA_MIN) * raw).toFloat()
    val coreRadiusPx = (CORE_DIAMETER_DP / 2f).dp.toPx() * scale

    // Glow: larger, more transparent circle behind the core
    drawCircle(
        color = color.copy(alpha = alpha * GLOW_ALPHA_FACTOR),
        radius = coreRadiusPx * CORE_GLOW_RADIUS_FACTOR,
        center = center
    )
    drawCircle(
        color = color.copy(alpha = alpha),
        radius = coreRadiusPx,
        center = center
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawOrbitalDot(
    center: Offset,
    orbit: Orbit,
    tSeconds: Double,
    color: Color
) {
    // Linear angular motion. Phase offset is realised by adding the (negative)
    // delay seconds to the elapsed time before mapping to an angle.
    val phaseAdjustedSeconds = tSeconds + orbit.phaseSeconds
    val angleRadians = 2 * PI * (phaseAdjustedSeconds / orbit.durationSeconds)
    val orbitRadiusPx = orbit.radiusDp.dp.toPx()
    val pos = Offset(
        center.x + (cos(angleRadians) * orbitRadiusPx).toFloat(),
        center.y + (sin(angleRadians) * orbitRadiusPx).toFloat()
    )

    val dotRadiusPx = (orbit.sizeDp / 2f).dp.toPx()
    drawCircle(
        color = color.copy(alpha = DOT_GLOW_ALPHA),
        radius = dotRadiusPx * DOT_GLOW_RADIUS_FACTOR,
        center = pos
    )
    drawCircle(
        color = color.copy(alpha = DOT_ALPHA),
        radius = dotRadiusPx,
        center = pos
    )
}

private data class Orbit(
    val radiusDp: Float,
    val durationSeconds: Double,
    val phaseSeconds: Double,
    val sizeDp: Float
)

private val ORBITS = listOf(
    Orbit(radiusDp = 30f, durationSeconds = 6.5, phaseSeconds = 0.0, sizeDp = 5.0f),
    Orbit(radiusDp = 30f, durationSeconds = 6.5, phaseSeconds = 1.3, sizeDp = 4.0f),
    Orbit(radiusDp = 42f, durationSeconds = 9.0, phaseSeconds = 0.4, sizeDp = 3.5f),
    Orbit(radiusDp = 42f, durationSeconds = 9.0, phaseSeconds = 3.0, sizeDp = 3.0f),
    Orbit(radiusDp = 42f, durationSeconds = 9.0, phaseSeconds = 5.6, sizeDp = 3.5f)
)

private const val CONTAINER_SIZE_DP = 110
private const val CORE_DIAMETER_DP = 8f
private const val CORE_CYCLE_SECONDS = 4.2
private const val CORE_SCALE_MIN = 0.9
private const val CORE_SCALE_MAX = 1.15
private const val CORE_ALPHA_MIN = 0.7
private const val CORE_ALPHA_MAX = 1.0
private const val CORE_GLOW_RADIUS_FACTOR = 2.5f
private const val GLOW_ALPHA_FACTOR = 0.6f
private const val DOT_ALPHA = 0.7f
private const val DOT_GLOW_ALPHA = 0.42f
private const val DOT_GLOW_RADIUS_FACTOR = 2.5f
