package com.stillmoment.presentation.ui.common

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.domain.models.MeditationPhase
import kotlin.math.cos
import kotlin.math.sin

private const val DEFAULT_OUTER_SIZE_DP = 280
private const val GLOW_RATIO = 220f / 280f
private const val LINE_WIDTH_DP = 3
private const val DOT_SIZE_DP = 9

// Halbe Periode mit RepeatMode.Reverse → Vollzyklus 16 s.
private const val BREATH_HALF_PERIOD_MS = 8_000

private data class GlowState(val scale: Float, val opacity: Float)

/**
 * Atemkreis mit drei Schichten — geteilte Visualisierung fuer den Player:
 * 1. Statischer Ring-Hintergrund (Track) — in jeder Phase sichtbar
 * 2. Restzeit-Bogen + Sonnen-Punkt — nur in der Hauptphase
 * 3. Atem-Glow im Inneren (animiert in der Hauptphase)
 *
 * In der Pre-Roll-Phase ist nur der statische Track zu sehen; die verbleibende
 * Vorbereitungszeit kommuniziert sich allein durch die Countdown-Zahl im Inneren.
 *
 * Die Komponente ist visuell — Logik (Phase, Progress, Reduced-Motion-Status)
 * kommt vom aufrufenden View. Keine Player-spezifischen Annahmen — Inhalt wird
 * via [content]-Slot injiziert.
 */
@Composable
fun BreathingCircle(
    phase: MeditationPhase,
    progress: Float,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    outerSize: Dp = DEFAULT_OUTER_SIZE_DP.dp,
    content: @Composable () -> Unit
) {
    val trackColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
    val accentColor = MaterialTheme.colorScheme.primary
    val glow = rememberGlowState(phase = phase, reduceMotion = reduceMotion)

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier.size(outerSize)
    ) {
        Canvas(modifier = Modifier.size(outerSize)) {
            drawTrackAndProgress(
                phase = phase,
                progress = progress,
                trackColor = trackColor,
                accentColor = accentColor
            )
        }
        BreathingGlow(
            accentColor = accentColor,
            scale = glow.scale,
            opacity = glow.opacity,
            size = outerSize * GLOW_RATIO,
            content = content
        )
    }
}

@Composable
private fun rememberGlowState(phase: MeditationPhase, reduceMotion: Boolean): GlowState {
    // Atem-Animation laeuft kontinuierlich — auch bei Pause.
    // In Pre-Roll und Reduced-Motion bleibt der Wert beim Mittelwert.
    val infiniteTransition = rememberInfiniteTransition(label = "breath")
    val breath by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(BREATH_HALF_PERIOD_MS, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "breathProgress"
    )

    val scale = when {
        phase == MeditationPhase.PreRoll -> 0.92f
        reduceMotion -> 0.92f
        else -> 0.85f + breath * 0.25f
    }
    val opacity = when {
        phase == MeditationPhase.PreRoll -> 0.55f
        reduceMotion -> 0.78f
        else -> 0.55f + breath * 0.45f
    }
    return GlowState(scale = scale, opacity = opacity)
}

private fun DrawScope.drawTrackAndProgress(
    phase: MeditationPhase,
    progress: Float,
    trackColor: Color,
    accentColor: Color
) {
    val stroke = LINE_WIDTH_DP.dp.toPx()
    val diameter = size.minDimension - stroke
    val topLeft = Offset(stroke / 2f, stroke / 2f)
    val arcSize = Size(diameter, diameter)

    drawArc(
        color = trackColor,
        startAngle = 0f,
        sweepAngle = 360f,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = stroke)
    )

    if (phase != MeditationPhase.Playing) return

    val sweep = progress.coerceIn(0f, 1f) * 360f
    if (sweep > 0f) {
        drawArc(
            color = accentColor,
            startAngle = -90f,
            sweepAngle = sweep,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = stroke, cap = StrokeCap.Round)
        )
    }
    drawSunDot(sweep = sweep, stroke = stroke, accentColor = accentColor)
}

private fun DrawScope.drawSunDot(sweep: Float, stroke: Float, accentColor: Color) {
    val dotRadius = DOT_SIZE_DP.dp.toPx() / 2f
    val centerX = size.width / 2f
    val centerY = size.height / 2f
    val ringRadius = (size.minDimension - stroke) / 2f
    val angleRad = (sweep - 90f) * (Math.PI / 180.0)
    val dotX = centerX + ringRadius * cos(angleRad).toFloat()
    val dotY = centerY + ringRadius * sin(angleRad).toFloat()
    drawCircle(
        color = accentColor.copy(alpha = 0.35f),
        radius = dotRadius * 1.8f,
        center = Offset(dotX, dotY)
    )
    drawCircle(
        color = accentColor,
        radius = dotRadius,
        center = Offset(dotX, dotY)
    )
}

@Composable
private fun BreathingGlow(accentColor: Color, scale: Float, opacity: Float, size: Dp, content: @Composable () -> Unit) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.size(size)
    ) {
        Canvas(
            modifier = Modifier
                .size(size)
                .scale(scale)
                .alpha(opacity)
        ) {
            drawCircle(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0.0f to accentColor.copy(alpha = 0.55f),
                        0.6f to accentColor.copy(alpha = 0.20f),
                        1.0f to Color.Transparent
                    ),
                    center = center,
                    radius = this.size.minDimension / 2f
                ),
                radius = this.size.minDimension / 2f
            )
        }
        content()
    }
}
