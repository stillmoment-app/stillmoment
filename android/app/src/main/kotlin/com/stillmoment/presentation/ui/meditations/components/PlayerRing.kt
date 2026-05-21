package com.stillmoment.presentation.ui.meditations.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlin.math.cos
import kotlin.math.sin

private const val DEFAULT_OUTER_SIZE_DP = 280
private const val TRACK_STROKE_DP = 1
private const val ARC_STROKE_DP = 1.5f
private const val BEAD_DIAMETER_DP = 12
private const val BEAD_HALO_MULTIPLIER = 1.8f
private const val BEAD_HALO_ALPHA = 0.35f
private const val TRACK_ALPHA = 0.32f
private const val ARC_ALPHA = 0.72f
private const val PROGRESS_ANIMATION_DURATION_MS = 1000

/**
 * Ring-Komponente des Guided-Meditation-Players im KS-2.0-Vokabular (shared-096).
 *
 * Drei Zeichen-Schichten im selben Canvas — Geometrie identisch zum Timer-Idle-
 * Ring, zentriert, Start bei 12 Uhr, im Uhrzeigersinn wachsend:
 *
 * 1. **Track** — 1 dp Vollkreis, warme leise Akzent-Linie (`primary @ 0.32`).
 *    In jeder Phase sichtbar.
 * 2. **Restzeit-Bogen** — 1.5 dp, dieselbe Akzentfarbe etwas kraeftiger
 *    (`primary @ 0.72`), abgerundete Enden. Nur in der Hauptphase sichtbar;
 *    Pre-Roll zeigt allein die Countdown-Zahl im Inneren.
 * 3. **Perle** — 12 dp Disc in `primary` mit weichem Halo (22 dp @ 0.35) an
 *    der Vorderkante des Bogens — Doppel-Disc-Surrogat fuer ein weiches
 *    Drop-Shadow. Nur in der Hauptphase sichtbar.
 *
 * Inhalt (Pause-Button + `PlayerCenterDisc` in der Hauptphase, Countdown im
 * Pre-Roll) wird via [content]-Slot injiziert — die Ring-Komponente trifft
 * keine Player-spezifischen Annahmen.
 *
 * Keine Atem-Animation, kein `rememberInfiniteTransition`, kein
 * `reduceMotion`-Branch — nichts bewegt sich ausser der Perle, deren Position
 * via `animateFloatAsState` linear ueber 1 s zwischen den 1-Hz-`progress`-
 * Updates interpoliert wird (Cross-Fade), sodass die Wanderung glatt wirkt.
 * Im Pause-Zustand zaehlt `progress` nicht weiter und die Perle friert
 * automatisch ein; im Pre-Roll werden Bogen und Perle uebersprungen.
 *
 * Pendant zu iOS' `PlayerRingView` (dort
 * `.animation(.linear(duration: 1.0), value: self.progress)`).
 *
 * @param phase Aktuelle Player-Phase. In [MeditationPhase.PreRoll] werden Bogen
 *   und Perle uebersprungen; nur die Track-Linie ist sichtbar.
 * @param progress Fortschritt der Hauptphase (0..1). Wird intern auf 0..1
 *   geklammert. In Pre-Roll ignoriert.
 * @param outerSize Aussendurchmesser des Rings. Default 280 dp.
 * @param content Mittig zentrierter Inhalt (Pause-Button + Disc oder
 *   Countdown).
 */
@Composable
fun PlayerRing(
    phase: MeditationPhase,
    progress: Float,
    modifier: Modifier = Modifier,
    outerSize: Dp = DEFAULT_OUTER_SIZE_DP.dp,
    content: @Composable () -> Unit,
) {
    val accentColor = MaterialTheme.colorScheme.primary
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = tween(durationMillis = PROGRESS_ANIMATION_DURATION_MS, easing = LinearEasing),
        label = "PlayerRingProgress",
    )

    Box(
        modifier = modifier.size(outerSize),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.size(outerSize)) {
            drawTrack(accentColor = accentColor)
            if (phase == MeditationPhase.Playing) {
                drawProgressArc(progress = animatedProgress, accentColor = accentColor)
                drawProgressBead(progress = animatedProgress, accentColor = accentColor)
            }
        }
        content()
    }
}

private fun DrawScope.drawTrack(accentColor: Color) {
    val stroke = TRACK_STROKE_DP.dp.toPx().coerceAtLeast(1f)
    val diameter = size.minDimension - stroke
    val topLeft = Offset(stroke / 2f, stroke / 2f)
    val arcSize = Size(diameter, diameter)

    drawArc(
        color = accentColor.copy(alpha = TRACK_ALPHA),
        startAngle = 0f,
        sweepAngle = 360f,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = stroke),
    )
}

private fun DrawScope.drawProgressArc(progress: Float, accentColor: Color) {
    val stroke = ARC_STROKE_DP.dp.toPx()
    val diameter = size.minDimension - stroke
    val topLeft = Offset(stroke / 2f, stroke / 2f)
    val arcSize = Size(diameter, diameter)
    val sweep = progress.coerceIn(0f, 1f) * 360f
    if (sweep <= 0f) return

    drawArc(
        color = accentColor.copy(alpha = ARC_ALPHA),
        startAngle = -90f,
        sweepAngle = sweep,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = stroke, cap = StrokeCap.Round),
    )
}

private fun DrawScope.drawProgressBead(progress: Float, accentColor: Color) {
    val stroke = ARC_STROKE_DP.dp.toPx()
    val beadOffset = PlayerRingGeometry.beadOffset(
        progress = progress,
        outerSize = size.minDimension,
        stroke = stroke,
    )
    val center = Offset(
        x = size.width / 2f + beadOffset.x,
        y = size.height / 2f + beadOffset.y,
    )
    val beadRadius = BEAD_DIAMETER_DP.dp.toPx() / 2f

    drawCircle(
        color = accentColor.copy(alpha = BEAD_HALO_ALPHA),
        radius = beadRadius * BEAD_HALO_MULTIPLIER,
        center = center,
    )
    drawCircle(
        color = accentColor,
        radius = beadRadius,
        center = center,
    )
}

/**
 * Pure-Funktion zur Perlen-Position auf dem Restzeit-Bogen.
 *
 * Spiegelt iOS' Inline-Berechnung in `PlayerRingView.progressBead`. Start bei
 * 12 Uhr (Progress 0 → dy = -radius), Richtung im Uhrzeigersinn
 * (Progress 0.25 → dx = +radius). Progress wird auf 0..1 geklammert.
 *
 * Outside-of-Canvas berechnet, damit die Geometrie als Pure-Funktion testbar
 * ist (siehe `PlayerRingGeometryTest`).
 */
object PlayerRingGeometry {
    fun beadOffset(progress: Float, outerSize: Float, stroke: Float): Offset {
        val clamped = progress.coerceIn(0f, 1f)
        val radius = (outerSize - stroke) / 2f
        val angle = clamped * 2.0 * Math.PI
        val dx = radius * sin(angle).toFloat()
        val dy = -radius * cos(angle).toFloat()
        return Offset(dx, dy)
    }
}

// MARK: - Previews

@Preview(name = "PlayerRing - Playing 30%", showBackground = true, backgroundColor = 0xFF1A100A)
@Composable
private fun PlayerRingPlayingPreview() {
    StillMomentTheme {
        PlayerRing(phase = MeditationPhase.Playing, progress = 0.3f) {}
    }
}

@Preview(name = "PlayerRing - Pre-Roll", showBackground = true, backgroundColor = 0xFFFFE3D6)
@Composable
private fun PlayerRingPreRollPreview() {
    StillMomentTheme {
        PlayerRing(phase = MeditationPhase.PreRoll, progress = 0f) {}
    }
}

@Preview(name = "PlayerRing - Paused 65%", showBackground = true, backgroundColor = 0xFF1A100A)
@Composable
private fun PlayerRingPausedPreview() {
    // Pause-Zustand: kein gesonderter Phase-Wert, Bogen + Perle ruhen einfach,
    // weil progress nicht weiterzaehlt.
    StillMomentTheme {
        PlayerRing(phase = MeditationPhase.Playing, progress = 0.65f) {}
    }
}
