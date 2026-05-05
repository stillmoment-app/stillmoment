package com.stillmoment.presentation.util

import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/**
 * Liest die System-Einstellung "Animationen reduzieren".
 *
 * Android hat keine dedizierte "reduce motion"-Flag wie iOS. Stattdessen
 * setzen Nutzer:innen `Settings.Global.TRANSITION_ANIMATION_SCALE` auf `0`
 * (Entwickleroptionen oder Eingabehilfen → Animationen entfernen).
 *
 * Wert wird einmalig pro Composition gelesen — nicht reaktiv. Wenn Nutzer
 * den Schalter zur Laufzeit toggelt, greift der neue Wert beim naechsten
 * Oeffnen des Players. Das entspricht dem iOS-Verhalten.
 */
@Composable
fun rememberIsReducedMotion(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        val scale = Settings.Global.getFloat(
            context.contentResolver,
            Settings.Global.TRANSITION_ANIMATION_SCALE,
            1f
        )
        scale == 0f
    }
}
