package com.stillmoment.presentation.ui.timer.components

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Eyebrow-Sektions-Ueberschrift fuer die Gong-Auswahl-Screens (shared-115/shared-118).
 *
 * Aus `SelectGongScreen` extrahiert, damit der Start-/End-Gong-Screen und der
 * Intervall-Gong-Editor dieselben Eyebrow-Labels teilen, ohne den Stil zu duplizieren
 * und auseinanderdriften zu lassen.
 */
@Composable
fun EyebrowLabel(@StringRes textRes: Int, modifier: Modifier = Modifier) {
    Text(
        text = TextStyle.eyebrow.applyCase(stringResource(textRes)),
        style = TextStyle.eyebrow.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.padding(horizontal = 6.dp)
    )
}

/**
 * Erklaerender Hinweistext fuer die Vibrations-Option (shared-115/shared-118).
 *
 * Erscheint anstelle der Lautstaerke-Karte, wenn „Vibration" gewaehlt ist. Geteilt
 * zwischen Start-/End-Gong-Screen und Intervall-Gong-Editor.
 */
@Composable
fun VibrationHelper(modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.praxis_gong_vibration_helper),
        style = TextStyle.body.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .padding(top = 12.dp, bottom = 4.dp)
    )
}
