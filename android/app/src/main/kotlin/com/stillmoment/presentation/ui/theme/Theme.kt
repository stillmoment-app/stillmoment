package com.stillmoment.presentation.ui.theme

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwitchColors
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * CompositionLocal providing the current dark theme state.
 * Used by TypographyRole.textStyle() for dark mode halation compensation.
 */
val LocalIsDarkTheme = compositionLocalOf { false }

/**
 * Additional semantic colors not covered by Material 3 ColorScheme.
 * These map to iOS ThemeColors roles that have no Material 3 equivalent.
 */
data class StillMomentColors(
    /** Timer ring progress color */
    val progress: Color,
    /** Toggle/Slider inactive track color (WCAG >= 3:1 vs cardBackground) */
    val controlTrack: Color,
    /** Card background color (Light ~= bgPrimary, Dark = own value) */
    val cardBackground: Color,
    /** Card border: Light = Transparent, Dark = subtle stroke */
    val cardBorder: Color,
    /** Divider color for the flat settings list on the timer idle screen (shared-089) */
    val settingsDivider: Color,
    /** Accent color for the value text in the flat settings list (shared-089) */
    val settingsValueAccent: Color,
    /** Active arc color of the BreathDial picker (shared-086) */
    val dialActiveArc: Color,
    /** Halo color (with alpha) around the BreathDial droplet (shared-086) */
    val dialDropletHalo: Color,
    /** Core fill color of the BreathDial droplet (shared-086) */
    val dialDropletCore: Color
)

/**
 * CompositionLocal providing the current StillMomentColors.
 * Access via `LocalStillMomentColors.current` in Composables.
 */
val LocalStillMomentColors = staticCompositionLocalOf {
    buildStillMomentColors(
        progress = SmLightProgress,
        controlTrack = SmLightControlTrack,
        cardBackground = SmLightCardBackground,
        cardBorder = SmLightCardBorder,
        interactive = SmLightInteractive
    )
}

/**
 * Resolve StillMomentColors for the given dark mode state.
 * Internal visibility for testability.
 */
internal fun resolveStillMomentColors(darkTheme: Boolean): StillMomentColors = if (darkTheme) {
    buildStillMomentColors(
        progress = SmDarkProgress,
        controlTrack = SmDarkControlTrack,
        cardBackground = SmDarkCardBackground,
        cardBorder = SmDarkCardBorder,
        interactive = SmDarkInteractive
    )
} else {
    buildStillMomentColors(
        progress = SmLightProgress,
        controlTrack = SmLightControlTrack,
        cardBackground = SmLightCardBackground,
        cardBorder = SmLightCardBorder,
        interactive = SmLightInteractive
    )
}

/**
 * Builds [StillMomentColors] with derived shared-086/089 tokens. Centralised so the
 * derivation rules (alpha for divider/halo, primary as accent/arc/core) live in one
 * place and stay consistent across both light and dark variants.
 */
private fun buildStillMomentColors(
    progress: Color,
    controlTrack: Color,
    cardBackground: Color,
    cardBorder: Color,
    interactive: Color
): StillMomentColors = StillMomentColors(
    progress = progress,
    controlTrack = controlTrack,
    cardBackground = cardBackground,
    cardBorder = cardBorder,
    settingsDivider = controlTrack.copy(alpha = 0.30f),
    settingsValueAccent = interactive,
    dialActiveArc = interactive,
    dialDropletHalo = interactive.copy(alpha = 0.18f),
    dialDropletCore = interactive
)

/**
 * Still Moment Theme — single curated palette with Light + Dark variants.
 * Color values taken 1:1 from iOS ThemeColors+Palettes.swift.
 */

// region Color Schemes

private val StillMomentLightScheme =
    lightColorScheme(
        primary = SmLightInteractive,
        onPrimary = Color.White,
        primaryContainer = SmLightAccentBg,
        onPrimaryContainer = SmLightTextPrimary,
        secondary = SmLightTextSecondary,
        onSecondary = Color.White,
        secondaryContainer = SmLightBgPrimary,
        onSecondaryContainer = SmLightTextPrimary,
        tertiary = SmLightInteractive,
        onTertiary = Color.White,
        background = SmLightBgSecondary,
        onBackground = SmLightTextPrimary,
        surface = SmLightBgSecondary,
        onSurface = SmLightTextPrimary,
        surfaceVariant = SmLightBgPrimary,
        onSurfaceVariant = SmLightTextSecondary,
        surfaceContainerLowest = SmLightBgPrimary,
        surfaceContainerLow = SmLightBgPrimary,
        surfaceContainer = SmLightBgPrimary,
        surfaceContainerHigh = SmLightBgPrimary,
        surfaceContainerHighest = SmLightBgPrimary,
        error = SmLightError,
        onError = Color.White,
        outline = SmLightRingTrack,
        outlineVariant = SmLightRingTrack
    )

private val StillMomentDarkScheme =
    darkColorScheme(
        primary = SmDarkInteractive,
        onPrimary = SmDarkTextOnInteractive,
        primaryContainer = SmDarkAccentBg,
        onPrimaryContainer = SmDarkTextPrimary,
        secondary = SmDarkTextSecondary,
        onSecondary = SmDarkTextOnInteractive,
        secondaryContainer = SmDarkBgPrimary,
        onSecondaryContainer = SmDarkTextPrimary,
        tertiary = SmDarkInteractive,
        onTertiary = SmDarkTextOnInteractive,
        background = SmDarkBgSecondary,
        onBackground = SmDarkTextPrimary,
        surface = SmDarkBgSecondary,
        onSurface = SmDarkTextPrimary,
        surfaceVariant = SmDarkBgPrimary,
        onSurfaceVariant = SmDarkTextSecondary,
        surfaceContainerLowest = SmDarkBgPrimary,
        surfaceContainerLow = SmDarkBgPrimary,
        surfaceContainer = SmDarkBgPrimary,
        surfaceContainerHigh = SmDarkBgPrimary,
        surfaceContainerHighest = SmDarkBgPrimary,
        error = SmDarkError,
        onError = Color.White,
        outline = SmDarkRingTrack,
        outlineVariant = SmDarkRingTrack
    )

// endregion

/**
 * Resolve the Material3 ColorScheme for the given dark mode state.
 * Internal visibility for testability.
 */
internal fun resolveColorScheme(darkTheme: Boolean): ColorScheme =
    if (darkTheme) StillMomentDarkScheme else StillMomentLightScheme

@Composable
fun StillMomentTheme(darkTheme: Boolean = false, content: @Composable () -> Unit) {
    val colorScheme = resolveColorScheme(darkTheme)
    val stillMomentColors = resolveStillMomentColors(darkTheme)
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            // Safe cast for Compose Preview compatibility
            val activity = view.context as? Activity ?: return@SideEffect
            val window = activity.window
            @Suppress("DEPRECATION")
            window.statusBarColor = Color.Transparent.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.Transparent.toArgb()
            val isLightAppearance = !darkTheme
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = isLightAppearance
                isAppearanceLightNavigationBars = isLightAppearance
            }
        }
    }

    CompositionLocalProvider(
        LocalIsDarkTheme provides darkTheme,
        LocalStillMomentColors provides stillMomentColors
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = StillMomentTypography,
            content = content
        )
    }
}

/**
 * Consistent Switch colors across the app.
 * Uses primary/onPrimary for checked state (M3 convention) and
 * onSurface/controlTrack for unchecked state to ensure contrast in dark mode.
 */
@Composable
fun stillMomentSwitchColors(): SwitchColors = SwitchDefaults.colors(
    checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
    checkedTrackColor = MaterialTheme.colorScheme.primary,
    uncheckedThumbColor = MaterialTheme.colorScheme.onSurface,
    uncheckedTrackColor = LocalStillMomentColors.current.controlTrack
)

/**
 * Warm gradient background matching iOS design.
 * Uses current theme's colorScheme for reactive gradient colors.
 * Gradient: surfaceVariant -> background -> primaryContainer.
 */
@Composable
fun WarmGradientBackground(modifier: Modifier = Modifier) {
    Box(
        modifier =
        modifier
            .fillMaxSize()
            .background(
                brush =
                Brush.verticalGradient(
                    colors =
                    listOf(
                        MaterialTheme.colorScheme.surfaceVariant,
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.primaryContainer,
                    )
                )
            )
    )
}
