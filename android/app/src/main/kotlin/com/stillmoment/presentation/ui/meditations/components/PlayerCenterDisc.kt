package com.stillmoment.presentation.ui.meditations.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.StillMomentTheme

private val DEFAULT_SIZE = 220.dp

// Hex-Werte 1:1 aus iOS' PlayerCenterDisc.swift (KS-2.0-Player-Handoff).
// Im Dark Mode leicht waermer und sichtbarer, im Light Mode dezenter.
private val DiscWarmDark = Color(0xFFD68A6E) // rgb(214, 138, 110)
private val DiscWarmDarkMid = Color(0xFFC77D63) // rgb(199, 125, 99)
private val DiscWarmLight = Color(0xFFA2503E) // rgb(162, 80, 62)

private const val DARK_ALPHA_INNER = 0.10f
private const val DARK_ALPHA_MID = 0.04f
private const val LIGHT_ALPHA_INNER = 0.07f
private const val LIGHT_ALPHA_MID = 0.03f

/**
 * Statische Gluehscheibe hinter dem Pause-Button im Player-Ring (shared-096).
 *
 * Kein Skalieren, kein Pulsieren, kein Opazitaets-Wechsel — reine visuelle
 * Ruhezone, die den zentralen Bereich des Rings warm anhebt. Im Dark Mode
 * leicht waermer und sichtbarer, im Light Mode dezenter. Hex-Werte und
 * Opacities folgen dem KS-2.0-Player-Handoff, 1:1 vom iOS-Pendant.
 *
 * Dekoration — kein `contentDescription`/`semantics`-Block (Compose-Default:
 * `Box`/`Canvas` ohne Semantics-Modifier sind nicht im a11y-Tree).
 */
@Composable
fun PlayerCenterDisc(modifier: Modifier = Modifier, size: Dp = DEFAULT_SIZE) {
    val isDark = isSystemInDarkTheme()

    val stops = if (isDark) {
        arrayOf(
            0.0f to DiscWarmDark.copy(alpha = DARK_ALPHA_INNER),
            0.5f to DiscWarmDarkMid.copy(alpha = DARK_ALPHA_MID),
            0.8f to Color.Transparent,
            1.0f to Color.Transparent,
        )
    } else {
        arrayOf(
            0.0f to DiscWarmLight.copy(alpha = LIGHT_ALPHA_INNER),
            0.5f to DiscWarmLight.copy(alpha = LIGHT_ALPHA_MID),
            0.8f to Color.Transparent,
            1.0f to Color.Transparent,
        )
    }

    Canvas(modifier = modifier.size(size)) {
        val radius = this.size.minDimension / 2f
        drawCircle(
            brush = Brush.radialGradient(
                colorStops = stops,
                center = center,
                radius = radius,
            ),
            radius = radius,
            center = center,
        )
    }
}

// MARK: - Previews

@Preview(name = "Disc - Dark", showBackground = true, backgroundColor = 0xFF1A100A)
@Composable
private fun PlayerCenterDiscDarkPreview() {
    StillMomentTheme {
        PlayerCenterDisc()
    }
}

@Preview(name = "Disc - Light", showBackground = true, backgroundColor = 0xFFFFE3D6)
@Composable
private fun PlayerCenterDiscLightPreview() {
    StillMomentTheme {
        PlayerCenterDisc()
    }
}
