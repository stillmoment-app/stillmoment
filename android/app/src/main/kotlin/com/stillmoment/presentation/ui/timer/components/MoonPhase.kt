package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlin.math.roundToInt

private const val ANIMATION_MS = 1000
private const val HALO_OUTER_RATIO = 1.6f
private const val DISC_GRADIENT_RADIUS_RATIO = 0.8f
private const val DISC_GRADIENT_CENTER_RATIO = 0.35f
private const val HALO_INNER_ALPHA_FALLOFF = 0.5f
private val DEFAULT_OUTER_SIZE = 220.dp

// --- Mondfarben (Handoff: claude_code_handoff_running_timer_mondphase) ---
// Werte 1:1 aus der iOS-Implementation (MoonPhaseView.swift) gespiegelt, damit
// beide Plattformen den gleichen Mond zeigen.

private val DiscFromLight = Color(0xFFFFF3DD)
private val DiscMidLight = Color(0xFFE8C896)
private val DiscToLight = Color(0xFF9A6A42)
private val ShadowLight = Color(0xFF3A2418)
private val HaloFromLight = Color(0xFFFCE8C8)
private val HaloToLight = Color(0xFFB85F46)

private val DiscFromDark = Color(0xFFF4E2C8)
private val DiscMidDark = Color(0xFFD5A878)
private val DiscToDark = Color(0xFF8B5F3E)
private val ShadowDark = Color(0xFF1A100C)
private val HaloFromDark = Color(0xFFF2C8A8)
private val HaloToDark = Color(0xFFC77D63)

private data class MoonPalette(
    val discFrom: Color,
    val discMid: Color,
    val discTo: Color,
    val shadow: Color,
    val haloFrom: Color,
    val haloTo: Color,
)

@Composable
private fun rememberMoonPalette(): MoonPalette {
    return if (isSystemInDarkTheme()) {
        MoonPalette(
            discFrom = DiscFromDark,
            discMid = DiscMidDark,
            discTo = DiscToDark,
            shadow = ShadowDark,
            haloFrom = HaloFromDark,
            haloTo = HaloToDark,
        )
    } else {
        MoonPalette(
            discFrom = DiscFromLight,
            discMid = DiscMidLight,
            discTo = DiscToLight,
            shadow = ShadowLight,
            haloFrom = HaloFromLight,
            haloTo = HaloToLight,
        )
    }
}

/**
 * Mond, dessen Schatten linear ueber die Sitzungsdauer nach links wandert —
 * vom Neumond (`progress = 0`) zum Vollmond (`progress = 1`). Drei Layer:
 *
 * 1. **Halo** — radialer Schein hinter dem Mond, Intensitaet waechst smoothstep-
 *    gewichtet (bleibt lange unauffaellig, wird erst spaet warm).
 * 2. **Mond-Disc** — radialer Verlauf mit verschobenem Zentrum oben-links,
 *    erzeugt subtile Beleuchtung ohne Krater oder Flecken. Statisch.
 * 3. **Schatten-Disc** — schwarze Scheibe gleicher Groesse wie der Mond, deren
 *    x-Offset linear mit dem Progress nach links driftet. Mond + Schatten
 *    werden auf einen `CircleShape` clip-maskiert, sodass der Schatten beim
 *    Verlassen des Mondes verschwindet — am Sitzungsende kein dunkler Rest
 *    links neben dem Mond.
 *
 * Farben sind aus dem Handoff `claude_code_handoff_running_timer_mondphase`
 * final und in dieser Composable hardcoded (Light/Dark via [isSystemInDarkTheme]).
 * Pendant zu iOS' `MoonPhaseView` (1:1-Hex-Werte).
 *
 * Mond ist Dekoration — kein eigenes `contentDescription`/`semantics`-Block.
 * TalkBack liest die Zeit-Anzeige unabhaengig.
 *
 * @param progress Sitzungs-Fortschritt 0..1. Wird intern geklammert.
 * @param reduceMotion Ob die System-Einstellung "Animationen reduzieren" aktiv
 *   ist. Bei `true` springen Schatten + Halo diskret zum neuen Wert
 *   (`snap()`), sonst fliessen sie linear in einer Sekunde.
 * @param outerSize Mond-Durchmesser. Halo-Container ist `outerSize × 1.6`.
 */
@Composable
fun MoonPhase(
    progress: Float,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    outerSize: Dp = DEFAULT_OUTER_SIZE,
) {
    val palette = rememberMoonPalette()
    val density = LocalDensity.current

    val outerSizePx = with(density) { outerSize.toPx() }
    val containerSize = outerSize * HALO_OUTER_RATIO

    val targetShadowOffsetPx = MoonPhaseGeometry.shadowOffset(progress, outerSizePx)
    val targetHaloAlpha = MoonPhaseGeometry.haloAlpha(progress)

    val shadowSpec = if (reduceMotion) snap() else tween<Float>(ANIMATION_MS, easing = LinearEasing)
    val haloSpec = if (reduceMotion) snap() else tween<Float>(ANIMATION_MS, easing = LinearEasing)

    val animatedShadowOffsetPx by animateFloatAsState(
        targetValue = targetShadowOffsetPx,
        animationSpec = shadowSpec,
        label = "moonShadowOffset",
    )
    val animatedHaloAlpha by animateFloatAsState(
        targetValue = targetHaloAlpha,
        animationSpec = haloSpec,
        label = "moonHaloAlpha",
    )

    Box(
        modifier = modifier.size(containerSize),
        contentAlignment = Alignment.Center,
    ) {
        MoonHalo(
            haloFrom = palette.haloFrom,
            haloTo = palette.haloTo,
            alpha = animatedHaloAlpha,
            containerSize = containerSize,
        )

        MoonDiscWithShadow(
            outerSize = outerSize,
            shadowOffsetPx = animatedShadowOffsetPx,
            palette = palette,
        )
    }
}

@Composable
private fun MoonHalo(haloFrom: Color, haloTo: Color, alpha: Float, containerSize: Dp) {
    Box(
        modifier = Modifier
            .size(containerSize)
            .background(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0f to haloFrom.copy(alpha = alpha),
                        0.4f to haloTo.copy(alpha = alpha * HALO_INNER_ALPHA_FALLOFF),
                        0.7f to Color.Transparent,
                    ),
                ),
                shape = CircleShape,
            ),
    )
}

@Composable
private fun MoonDiscWithShadow(outerSize: Dp, shadowOffsetPx: Float, palette: MoonPalette) {
    Box(
        modifier = Modifier
            .size(outerSize)
            .clip(CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        MoonDisc(outerSize = outerSize, palette = palette)
        ShadowDisc(outerSize = outerSize, offsetPx = shadowOffsetPx, color = palette.shadow)
    }
}

@Composable
private fun MoonDisc(outerSize: Dp, palette: MoonPalette) {
    val density = LocalDensity.current
    val outerSizePx = with(density) { outerSize.toPx() }
    val centerOffsetPx = outerSizePx * DISC_GRADIENT_CENTER_RATIO
    val radiusPx = outerSizePx * DISC_GRADIENT_RADIUS_RATIO

    Box(
        modifier = Modifier
            .size(outerSize)
            .background(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0f to palette.discFrom,
                        0.6f to palette.discMid,
                        1f to palette.discTo,
                    ),
                    center = Offset(centerOffsetPx, centerOffsetPx),
                    radius = radiusPx,
                ),
                shape = CircleShape,
            ),
    )
}

@Composable
private fun ShadowDisc(outerSize: Dp, offsetPx: Float, color: Color) {
    Box(
        modifier = Modifier
            .offset { IntOffset(offsetPx.roundToInt(), 0) }
            .size(outerSize)
            .background(color = color, shape = CircleShape),
    )
}

// MARK: - Previews

@Preview(name = "Moon - Neumond (Light)", showBackground = true, backgroundColor = 0xFFFFE3D6)
@Composable
private fun MoonPhaseNeumondLightPreview() {
    StillMomentTheme {
        MoonPhase(progress = 0f, reduceMotion = true)
    }
}

@Preview(name = "Moon - Halbmond (Light)", showBackground = true, backgroundColor = 0xFFFFE3D6)
@Composable
private fun MoonPhaseHalbmondLightPreview() {
    StillMomentTheme {
        MoonPhase(progress = 0.5f, reduceMotion = true)
    }
}

@Preview(name = "Moon - Vollmond (Light)", showBackground = true, backgroundColor = 0xFFFFE3D6)
@Composable
private fun MoonPhaseVollmondLightPreview() {
    StillMomentTheme {
        MoonPhase(progress = 1f, reduceMotion = true)
    }
}

@Preview(
    name = "Moon - Neumond (Dark)",
    showBackground = true,
    backgroundColor = 0xFF1A100A,
    uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun MoonPhaseNeumondDarkPreview() {
    StillMomentTheme {
        MoonPhase(progress = 0f, reduceMotion = true)
    }
}

@Preview(
    name = "Moon - Halbmond (Dark)",
    showBackground = true,
    backgroundColor = 0xFF1A100A,
    uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun MoonPhaseHalbmondDarkPreview() {
    StillMomentTheme {
        MoonPhase(progress = 0.5f, reduceMotion = true)
    }
}

@Preview(
    name = "Moon - Vollmond (Dark)",
    showBackground = true,
    backgroundColor = 0xFF1A100A,
    uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun MoonPhaseVollmondDarkPreview() {
    StillMomentTheme {
        MoonPhase(progress = 1f, reduceMotion = true)
    }
}

@Preview(
    name = "Moon - Compact (180 dp)",
    showBackground = true,
    backgroundColor = 0xFF1A100A,
    uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun MoonPhaseCompactPreview() {
    StillMomentTheme {
        MoonPhase(progress = 0.5f, reduceMotion = true, outerSize = 180.dp)
    }
}
