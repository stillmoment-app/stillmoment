package com.stillmoment.presentation.ui.timer.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import kotlin.math.roundToInt
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Charaktertragende Mini-Wellenform rechts in jeder Gong-Zeile (shared-115).
 *
 * Rendert 11 vertikale Balken, deren Hoehen einer festen Huellkurve je Klang
 * folgen (links = Anschlag, rechts = Ausklang). Die Vibration hat keine
 * Huellkurve und wird stattdessen als drei Punkte gezeichnet.
 *
 * Die Huellkurven-Werte sind eine geteilte Cross-Platform-Spezifikation und
 * muessen identisch zur iOS `waveEnvelopes`-Map bleiben, damit beide Plattformen
 * dieselbe Form rendern.
 */
@Composable
fun GongWaveform(soundId: String, isSelected: Boolean, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val barColor = if (isSelected) colors.interactive else colors.controlTrack
    val envelope = GongWaveformEnvelope.envelope(soundId)

    if (envelope != null) {
        WaveformBars(envelope = envelope, barColor = barColor, modifier = modifier)
    } else {
        HapticDots(dotColor = barColor, modifier = modifier)
    }
}

@Composable
private fun WaveformBars(envelope: ImmutableList<Float>, barColor: Color, modifier: Modifier = Modifier) {
    Canvas(
        modifier = modifier
            .height(GongWaveformEnvelope.MAX_BAR_HEIGHT.dp)
            .width(barsWidth(envelope.size))
    ) {
        drawBars(envelope = envelope, barColor = barColor)
    }
}

private fun barsWidth(barCount: Int): Dp =
    (GongWaveformEnvelope.BAR_WIDTH * barCount + GongWaveformEnvelope.BAR_SPACING * (barCount - 1)).dp

private fun DrawScope.drawBars(envelope: List<Float>, barColor: Color) {
    val barWidthPx = GongWaveformEnvelope.BAR_WIDTH.dp.toPx()
    val spacingPx = GongWaveformEnvelope.BAR_SPACING.dp.toPx()
    val centerY = size.height / 2f
    var x = 0f
    envelope.forEach { value ->
        val barHeightPx = GongWaveformEnvelope.barHeight(value).dp.toPx()
        drawLine(
            color = barColor,
            start = Offset(x + barWidthPx / 2f, centerY - barHeightPx / 2f),
            end = Offset(x + barWidthPx / 2f, centerY + barHeightPx / 2f),
            strokeWidth = barWidthPx,
            cap = StrokeCap.Round
        )
        x += barWidthPx + spacingPx
    }
}

@Composable
private fun HapticDots(dotColor: Color, modifier: Modifier = Modifier) {
    Canvas(
        modifier = modifier
            .height(GongWaveformEnvelope.MAX_BAR_HEIGHT.dp)
            .width(dotsWidth())
    ) {
        val diameterPx = GongWaveformEnvelope.DOT_DIAMETER.dp.toPx()
        val spacingPx = GongWaveformEnvelope.DOT_SPACING.dp.toPx()
        val centerY = size.height / 2f
        var x = diameterPx / 2f
        repeat(GongWaveformEnvelope.DOT_COUNT) {
            drawCircle(
                color = dotColor,
                radius = diameterPx / 2f,
                center = Offset(x, centerY)
            )
            x += diameterPx + spacingPx
        }
    }
}

private fun dotsWidth(): Dp {
    val dots = GongWaveformEnvelope.DOT_COUNT
    return (GongWaveformEnvelope.DOT_DIAMETER * dots + GongWaveformEnvelope.DOT_SPACING * (dots - 1)).dp
}

/**
 * Feste Huellkurven-Spezifikation, gekeyt nach Sound-ID (11 Balken je Klang).
 *
 * Geteilte Cross-Platform-Spezifikation — die Werte sind identisch zur iOS
 * `GongWaveform.waveEnvelopes`-Map. Gekeyt nach Sound-ID (nicht dem lokalisierten
 * Namen), damit Lokalisierung die gerenderte Form nie beeinflusst.
 */
object GongWaveformEnvelope {
    const val BAR_WIDTH = 2.5f
    const val BAR_SPACING = 2f
    const val MAX_BAR_HEIGHT = 20f
    const val DOT_DIAMETER = 6f
    const val DOT_SPACING = 4f
    const val DOT_COUNT = 3

    private const val MIN_BAR_HEIGHT = 4f
    private const val HEIGHT_RANGE = 16f

    private val waveEnvelopes: Map<String, ImmutableList<Float>> = mapOf(
        // tief, langer Ausklang
        "temple-bell" to persistentListOf(
            0.35f, 0.90f, 1.00f, 0.85f, 0.78f, 0.68f, 0.60f, 0.50f, 0.42f, 0.34f, 0.26f
        ),
        // hell, ausgewogen
        "classic-bowl" to persistentListOf(
            0.30f, 0.95f, 0.80f, 0.65f, 0.55f, 0.45f, 0.40f, 0.32f, 0.28f, 0.22f, 0.18f
        ),
        // sehr tief, breit, langer Nachhall
        "deep-resonance" to persistentListOf(
            0.45f, 0.70f, 0.90f, 1.00f, 0.92f, 0.86f, 0.80f, 0.72f, 0.64f, 0.54f, 0.44f
        ),
        // trocken, kurz
        "clear-strike" to persistentListOf(
            0.25f, 1.00f, 0.70f, 0.45f, 0.30f, 0.20f, 0.14f, 0.10f, 0.08f, 0.06f, 0.05f
        )
    )

    /**
     * Huellkurve fuer die gegebene Sound-ID, oder `null`, wenn der Klang keine
     * Wellenform hat (Vibration oder unbekannte ID).
     */
    fun envelope(soundId: String): ImmutableList<Float>? = waveEnvelopes[soundId]

    /**
     * Bildet einen normalisierten Huellkurven-Wert (0..1) auf eine Balkenhoehe
     * in dp ab (4–20dp).
     */
    fun barHeight(value: Float): Float {
        val clamped = value.coerceIn(0f, 1f)
        return MIN_BAR_HEIGHT + (clamped * HEIGHT_RANGE).roundToInt()
    }
}
