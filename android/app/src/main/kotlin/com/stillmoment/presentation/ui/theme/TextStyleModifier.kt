package com.stillmoment.presentation.ui.theme

import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.TextStyle as ComposeTextStyle
import com.stillmoment.presentation.ui.theme.TextStyle as TextToken

// Import-Alias: unser Token-Enum heisst `TextStyle`, Compose hat einen
// gleichnamigen Datentyp (`androidx.compose.ui.text.TextStyle`). In dieser Datei
// brauchen wir beide, daher der Alias. Aufrufer sehen das nicht — sie nutzen
// `TextStyle.body.toComposeTextStyle()`.

/**
 * `fontWeightAdjustment`-Schwelle, ab der wir den Bold-Text-Bump anwenden.
 *
 * Android 12+ liefert `300`, wenn der User „Schwere Schrift" in Bedienungs-
 * hilfen aktiviert. Auf API 26-30 ist die Property nicht vorhanden bzw.
 * immer `0` — Bump greift dort nicht (Setting existiert nicht).
 */
private const val BOLD_TEXT_WEIGHT_ADJUSTMENT = 300

/**
 * Liest das System-Bold-Text-Setting aus der aktuellen [LocalConfiguration].
 *
 * Auf API < 31 immer `false` (Property existiert dort nicht; siehe
 * [Android Configuration Reference](https://developer.android.com/reference/android/content/res/Configuration#fontWeightAdjustment)).
 *
 * Pendant zu iOS' `@Environment(\.legibilityWeight)`.
 */
@Composable
@ReadOnlyComposable
fun isBoldTextEnabled(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
    return LocalConfiguration.current.fontWeightAdjustment >= BOLD_TEXT_WEIGHT_ADJUSTMENT
}

/**
 * Wandelt einen Typografie-Token in ein Compose-`TextStyle`.
 *
 * Liest das System-Bold-Text-Setting und mapped Familie/Gewicht ueber
 * [TextToken.effectiveFamily] / [TextToken.effectiveWeight]. Setzt Tracking,
 * Style, Basis-Groesse und optional `fontFeatureSettings = "tnum"` fuer
 * tabular figures.
 *
 * Farbe wird **nicht** gesetzt — Plan-Regel "Hierarchie via Farbe, nicht via
 * Token". Caller setzt Farbe via `color = ...` am `Text(...)`-Composable.
 *
 * **Aufruf-Pattern:**
 * ```
 * Text(
 *     text = "Beispiel",
 *     style = TextStyle.body.toComposeTextStyle(),
 *     color = MaterialTheme.colorScheme.onSurface,
 * )
 *
 * // Mit tabular figures (Countdown):
 * Text(
 *     text = "12:34",
 *     style = TextStyle.micro.toComposeTextStyle(monospacedDigits = true),
 * )
 * ```
 *
 * @param monospacedDigits Aktiviert OpenType `tnum` (tabular figures) — z.B.
 *   fuer Countdown-Labels, damit Ziffern-Breite beim Herunterzaehlen nicht
 *   springt.
 */
@Composable
@ReadOnlyComposable
fun TextToken.toComposeTextStyle(monospacedDigits: Boolean = false): ComposeTextStyle {
    val boldEnabled = isBoldTextEnabled()
    return ComposeTextStyle(
        fontFamily = effectiveFamily(boldEnabled),
        fontSize = baseSize,
        fontWeight = effectiveWeight(boldEnabled),
        fontStyle = style,
        letterSpacing = tracking,
        fontFeatureSettings = if (monospacedDigits) "tnum" else null,
    )
}
