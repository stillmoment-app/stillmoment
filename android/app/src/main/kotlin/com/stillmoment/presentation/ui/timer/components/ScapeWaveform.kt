package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.util.rememberIsReducedMotion
import kotlin.math.roundToInt
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Charaktertragende Mini-Wellenform rechts in jeder Soundscape-Zeile (shared-121).
 *
 * Anders als die Gong-Wellenform (feste Abkling-Huellkurve fuer Einmal-Klang)
 * repraesentiert die Soundscape-Wellenform eine dauerhafte Schleife: 13 Balken,
 * deren Hoehen einer festen SWAVE-Huellkurve je Klang folgen, und die waehrend der
 * Vorschau als Equalizer animieren. "Stille" hat keine Huellkurve und wird als
 * ruhige flache Linie gezeichnet.
 *
 * Die SWAVE-Huellkurven sind eine geteilte Cross-Platform-Spezifikation und muessen
 * identisch zur iOS `swaveEnvelopes`-Map bleiben, damit beide Plattformen dieselbe
 * Form rendern.
 */
@Composable
fun ScapeWaveform(soundId: String, isSelected: Boolean, isPlaying: Boolean, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val barColor = if (isSelected) colors.interactive else colors.controlTrack
    val envelope = ScapeWaveformEnvelope.envelope(soundId)

    if (envelope != null) {
        WaveformBars(
            envelope = envelope,
            barColor = barColor,
            isPlaying = isPlaying,
            modifier = modifier
        )
    } else {
        FlatLine(lineColor = barColor, modifier = modifier)
    }
}

@Composable
private fun WaveformBars(
    envelope: ImmutableList<Float>,
    barColor: Color,
    isPlaying: Boolean,
    modifier: Modifier = Modifier
) {
    val reducedMotion = rememberIsReducedMotion()
    val animates = isPlaying && !reducedMotion
    val transition = rememberInfiniteTransition(label = "scapeEqualizer")

    Row(
        modifier = modifier.height(ScapeWaveformEnvelope.MAX_BAR_HEIGHT.dp),
        horizontalArrangement = Arrangement.spacedBy(ScapeWaveformEnvelope.BAR_SPACING.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        envelope.forEachIndexed { index, value ->
            // Equalizer: jeder Balken pulsiert zwischen voller und EQ_MIN_SCALE-Hoehe,
            // gestaffelt per Index (Pendant zum iOS `eq`-Keyframe).
            val scaleY by transition.animateFloat(
                initialValue = 1f,
                targetValue = if (animates) ScapeWaveformEnvelope.EQ_MIN_SCALE else 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(durationMillis = ScapeWaveformEnvelope.EQ_DURATION_MS),
                    repeatMode = RepeatMode.Reverse,
                    initialStartOffset = StartOffset(index * ScapeWaveformEnvelope.EQ_STAGGER_MS)
                ),
                label = "scapeBar$index"
            )
            Box(
                modifier = Modifier
                    .width(ScapeWaveformEnvelope.BAR_WIDTH.dp)
                    .height(ScapeWaveformEnvelope.barHeight(value).dp)
                    .graphicsLayer { this.scaleY = scaleY }
                    .clip(RoundedCornerShape(ScapeWaveformEnvelope.BAR_WIDTH.dp / 2))
                    .background(barColor)
            )
        }
    }
}

@Composable
private fun FlatLine(lineColor: Color, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.height(ScapeWaveformEnvelope.MAX_BAR_HEIGHT.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .width(ScapeWaveformEnvelope.FLAT_WIDTH.dp)
                .height(ScapeWaveformEnvelope.BAR_WIDTH.dp)
                .clip(RoundedCornerShape(ScapeWaveformEnvelope.BAR_WIDTH.dp / 2))
                .background(lineColor)
        )
    }
}

/**
 * Feste Loop-Huellkurven-Spezifikation, gekeyt nach Sound-ID (13 Balken je Klang).
 *
 * Geteilte Cross-Platform-Spezifikation — die Werte sind identisch zur iOS
 * `ScapeWaveform.swaveEnvelopes`-Map. Gekeyt nach Sound-ID (nicht dem lokalisierten
 * Namen), damit Lokalisierung die gerenderte Form nie beeinflusst. Dies sind
 * Loop-Muster (gleichmaessig), nicht die abklingenden Huellkurven der Gong-Wellenform.
 */
object ScapeWaveformEnvelope {
    const val BAR_WIDTH = 2.5f
    const val BAR_SPACING = 2f
    const val MAX_BAR_HEIGHT = 22f
    const val FLAT_WIDTH = 26f

    /** Equalizer-Animation: minimaler Hoehen-Faktor, Dauer und Index-Staffelung. */
    const val EQ_MIN_SCALE = 0.4f
    const val EQ_DURATION_MS = 900
    const val EQ_STAGGER_MS = 60

    private const val MIN_BAR_HEIGHT = 4f
    private const val HEIGHT_RANGE = 16f

    private val swaveEnvelopes: Map<String, ImmutableList<Float>> = mapOf(
        // Waldatmosphaere — sanftes Blaetterrauschen
        "forest" to persistentListOf(
            0.30f, 0.55f, 0.40f, 0.70f, 0.50f, 0.62f, 0.45f, 0.72f, 0.52f, 0.60f, 0.42f, 0.58f, 0.36f
        ),
        // Regen — gleichmaessiger, beruhigender Regen
        "cozy-rain" to persistentListOf(
            0.62f, 0.74f, 0.58f, 0.80f, 0.66f, 0.78f, 0.60f, 0.82f, 0.64f, 0.76f, 0.58f, 0.72f, 0.60f
        )
    )

    /**
     * Neutrales, ruhiges Loop-Muster fuer importierte/eigene Dateien (keine echte
     * Analyse). Identisch zum iOS-Default, damit beide Plattformen dieselbe Form rendern.
     */
    private val defaultEnvelope: ImmutableList<Float> = persistentListOf(
        0.45f, 0.55f, 0.48f, 0.60f, 0.50f, 0.58f, 0.46f, 0.62f, 0.50f, 0.56f, 0.44f, 0.54f, 0.42f
    )

    /**
     * Huellkurve fuer die gegebene Sound-ID, oder `null`, wenn der Klang keine
     * Wellenform hat ("Stille" rendert stattdessen eine flache Linie).
     *
     * Eingebaute Szenen nutzen ihre dedizierte SWAVE-Huellkurve; jede andere ID
     * (die UUID einer eigenen Datei) faellt auf den neutralen Default zurueck.
     */
    fun envelope(soundId: String): ImmutableList<Float>? {
        if (soundId == BackgroundSound.SILENT_ID) {
            return null
        }
        return swaveEnvelopes[soundId] ?: defaultEnvelope
    }

    /**
     * Bildet einen normalisierten Huellkurven-Wert (0..1) auf eine Balkenhoehe in
     * dp ab (4–20dp). Float-Mapping vermeidet Int-Overflow (Projekt-Memory).
     */
    fun barHeight(value: Float): Float {
        val clamped = value.coerceIn(0f, 1f)
        return MIN_BAR_HEIGHT + (clamped * HEIGHT_RANGE).roundToInt()
    }
}
