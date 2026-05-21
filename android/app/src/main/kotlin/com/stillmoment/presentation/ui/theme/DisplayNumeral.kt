package com.stillmoment.presentation.ui.theme

import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

/**
 * Floor fuer die Display-Ziffer in sp.
 *
 * Kleine Container (z.B. iPhone-SE-Pendant ohne Atemkreis-Durchmesser) sollen
 * trotzdem lesbare Ziffern haben.
 */
private const val MIN_DISPLAY_SIZE_SP = 56f

/**
 * Ceiling fuer die Display-Ziffer in sp.
 *
 * Auf grossen Geraeten (Tablet) soll die Ziffer nicht ueber den Atemkreis
 * hinauswachsen.
 */
private const val MAX_DISPLAY_SIZE_SP = 120f

/**
 * Faktor `Container-Durchmesser × 0.32 = Ziffer-Groesse`.
 *
 * Empirisch aus iOS-Plan uebernommen — 220dp (SE-Mond) → 70sp, 300dp
 * (Pro-Max-Klasse) → 96sp.
 */
private const val SIZE_FACTOR = 0.32f

/**
 * System-Font-Scale, ab dem die Display-Ziffer nicht mehr weiter skaliert.
 *
 * Pendant zu iOS' `DynamicTypeSize.accessibility2`-Cap. Ab dieser Stufe
 * verschiebt der aufrufende Layout-Code die Numerik unter den Container
 * (Folge-Ticket).
 */
private const val SCALE_CAP_THRESHOLD = 1.3f

/**
 * Singleton fuer reine Berechnungs-Helfer rund um Display-Numerik.
 *
 * Composable [DisplayNumeral] und das Berechnungs-Singleton liegen bewusst in
 * derselben Datei — der Composable laeuft im Compose-Kontext (liest
 * `LocalDensity`), [Companion.cappedSize] ist eine pure Funktion und damit
 * unit-testbar ohne Compose-Test-Harness.
 */
object DisplayNumeral {

    /**
     * Berechnet die Ziffergroesse aus Container-Durchmesser und System-Font-Scale.
     *
     * Algorithmus:
     * 1. `raw = containerDiameter * 0.32`
     * 2. `floored = max(raw, 56sp)`
     * 3. `ceiled = min(floored, 120sp)`
     * 4. Ab Font-Scale >= 1.3: keine weitere Skalierung (Plan-Regel — der
     *    Caller verschiebt die Numerik dann unter den Container).
     *
     * @param containerDiameter Durchmesser in `Dp`.
     * @param fontScale System-Font-Scale (1.0 = Default; 0.85 = small; 1.3
     *   = Largest auf den Stops, 2.0 = Accessibility).
     */
    fun cappedSize(containerDiameter: Dp, fontScale: Float): TextUnit {
        val raw = containerDiameter.value * SIZE_FACTOR
        val floored = maxOf(raw, MIN_DISPLAY_SIZE_SP)
        val ceiled = minOf(floored, MAX_DISPLAY_SIZE_SP)
        return if (fontScale >= SCALE_CAP_THRESHOLD) {
            ceiled.sp
        } else {
            (ceiled * fontScale).sp
        }
    }
}

/**
 * Display-Numerik (Timer-Idle, Timer-Running, Player-Countdown, Dial-Value).
 *
 * Container-relativ, damit das gleiche View ohne Magic Numbers auf jeder
 * Bildschirm-Klasse stimmt — von Pixel-3a-Class (220dp Mond) bis Tablet
 * (300dp Ring).
 *
 * Pendant zu iOS' `DisplayNumeral(text:, containerDiameter:)`.
 *
 * @param text Die anzuzeigende Numerik (z.B. `"15"`, `"12:34"`).
 * @param containerDiameter Durchmesser des umgebenden Containers
 *   (Atemkreis, Ring, Mond). Wird zur Berechnung der Schriftgroesse genutzt.
 * @param modifier Compose-Modifier (Test-Tags, Padding, semantics).
 * @param color Textfarbe. Default: `LocalContentColor.current` (folgt der
 *   `CompositionLocal`-Hierarchie wie `Text(...)`).
 */
@Composable
fun DisplayNumeralText(
    text: String,
    containerDiameter: Dp,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
) {
    val fontScale = LocalDensity.current.fontScale
    val size = DisplayNumeral.cappedSize(containerDiameter, fontScale)
    val resolvedColor = if (color != Color.Unspecified) color else LocalContentColor.current

    Text(
        text = text,
        modifier = modifier,
        color = resolvedColor,
        style = MaterialTheme.typography.displayLarge.copy(
            fontFamily = NewsreaderFontFamily,
            fontSize = size,
            fontWeight = FontWeight.Light,
            letterSpacing = (-1.5).sp,
            fontFeatureSettings = "tnum",
        ),
        textAlign = TextAlign.Center,
        maxLines = 1,
    )
}
