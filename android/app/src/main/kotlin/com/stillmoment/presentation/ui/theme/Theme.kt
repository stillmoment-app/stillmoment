package com.stillmoment.presentation.ui.theme

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.stillmoment.domain.models.ColorTheme

/**
 * Still Moment Theme - Multiple color themes with Material 3.
 * Supports light/dark variants for each theme.
 * Color values taken 1:1 from iOS ThemeColors+Palettes.swift.
 */

// region Color Schemes

private val CandlelightLightScheme =
    lightColorScheme(
        primary = CdLightInteractive,
        onPrimary = Color.White,
        primaryContainer = CdLightAccentBg,
        onPrimaryContainer = CdLightTextPrimary,
        secondary = CdLightTextSecondary,
        onSecondary = Color.White,
        secondaryContainer = CdLightBgPrimary,
        onSecondaryContainer = CdLightTextPrimary,
        tertiary = CdLightInteractive,
        onTertiary = Color.White,
        background = CdLightBgSecondary,
        onBackground = CdLightTextPrimary,
        surface = CdLightBgSecondary,
        onSurface = CdLightTextPrimary,
        surfaceVariant = CdLightBgPrimary,
        onSurfaceVariant = CdLightTextSecondary,
        surfaceContainerLowest = CdLightBgPrimary,
        surfaceContainerLow = CdLightBgPrimary,
        surfaceContainer = CdLightBgPrimary,
        surfaceContainerHigh = CdLightBgPrimary,
        surfaceContainerHighest = CdLightBgPrimary,
        error = CdLightError,
        onError = Color.White,
        outline = CdLightRingTrack,
        outlineVariant = CdLightRingTrack
    )

private val CandlelightDarkScheme =
    darkColorScheme(
        primary = CdDarkInteractive,
        onPrimary = CdDarkTextOnInteractive,
        primaryContainer = CdDarkAccentBg,
        onPrimaryContainer = CdDarkTextPrimary,
        secondary = CdDarkTextSecondary,
        onSecondary = CdDarkTextOnInteractive,
        secondaryContainer = CdDarkBgPrimary,
        onSecondaryContainer = CdDarkTextPrimary,
        tertiary = CdDarkInteractive,
        onTertiary = CdDarkTextOnInteractive,
        background = CdDarkBgSecondary,
        onBackground = CdDarkTextPrimary,
        surface = CdDarkBgSecondary,
        onSurface = CdDarkTextPrimary,
        surfaceVariant = CdDarkBgPrimary,
        onSurfaceVariant = CdDarkTextSecondary,
        surfaceContainerLowest = CdDarkBgPrimary,
        surfaceContainerLow = CdDarkBgPrimary,
        surfaceContainer = CdDarkBgPrimary,
        surfaceContainerHigh = CdDarkBgPrimary,
        surfaceContainerHighest = CdDarkBgPrimary,
        error = CdDarkError,
        onError = Color.White,
        outline = CdDarkRingTrack,
        outlineVariant = CdDarkRingTrack
    )

private val ForestLightScheme =
    lightColorScheme(
        primary = FoLightInteractive,
        onPrimary = FoLightTextOnInteractive,
        primaryContainer = FoLightAccentBg,
        onPrimaryContainer = FoLightTextPrimary,
        secondary = FoLightTextSecondary,
        onSecondary = FoLightTextOnInteractive,
        secondaryContainer = FoLightBgPrimary,
        onSecondaryContainer = FoLightTextPrimary,
        tertiary = FoLightInteractive,
        onTertiary = FoLightTextOnInteractive,
        background = FoLightBgSecondary,
        onBackground = FoLightTextPrimary,
        surface = FoLightBgSecondary,
        onSurface = FoLightTextPrimary,
        surfaceVariant = FoLightBgPrimary,
        onSurfaceVariant = FoLightTextSecondary,
        surfaceContainerLowest = FoLightBgPrimary,
        surfaceContainerLow = FoLightBgPrimary,
        surfaceContainer = FoLightBgPrimary,
        surfaceContainerHigh = FoLightBgPrimary,
        surfaceContainerHighest = FoLightBgPrimary,
        error = FoLightError,
        onError = Color.White,
        outline = FoLightRingTrack,
        outlineVariant = FoLightRingTrack
    )

private val ForestDarkScheme =
    darkColorScheme(
        primary = FoDarkInteractive,
        onPrimary = FoDarkTextOnInteractive,
        primaryContainer = FoDarkAccentBg,
        onPrimaryContainer = FoDarkTextPrimary,
        secondary = FoDarkTextSecondary,
        onSecondary = FoDarkTextOnInteractive,
        secondaryContainer = FoDarkBgPrimary,
        onSecondaryContainer = FoDarkTextPrimary,
        tertiary = FoDarkInteractive,
        onTertiary = FoDarkTextOnInteractive,
        background = FoDarkBgSecondary,
        onBackground = FoDarkTextPrimary,
        surface = FoDarkBgSecondary,
        onSurface = FoDarkTextPrimary,
        surfaceVariant = FoDarkBgPrimary,
        onSurfaceVariant = FoDarkTextSecondary,
        surfaceContainerLowest = FoDarkBgPrimary,
        surfaceContainerLow = FoDarkBgPrimary,
        surfaceContainer = FoDarkBgPrimary,
        surfaceContainerHigh = FoDarkBgPrimary,
        surfaceContainerHighest = FoDarkBgPrimary,
        error = FoDarkError,
        onError = Color.White,
        outline = FoDarkRingTrack,
        outlineVariant = FoDarkRingTrack
    )

private val MoonLightScheme =
    lightColorScheme(
        primary = MnLightInteractive,
        onPrimary = MnLightTextOnInteractive,
        primaryContainer = MnLightAccentBg,
        onPrimaryContainer = MnLightTextPrimary,
        secondary = MnLightTextSecondary,
        onSecondary = MnLightTextOnInteractive,
        secondaryContainer = MnLightBgPrimary,
        onSecondaryContainer = MnLightTextPrimary,
        tertiary = MnLightInteractive,
        onTertiary = MnLightTextOnInteractive,
        background = MnLightBgSecondary,
        onBackground = MnLightTextPrimary,
        surface = MnLightBgSecondary,
        onSurface = MnLightTextPrimary,
        surfaceVariant = MnLightBgPrimary,
        onSurfaceVariant = MnLightTextSecondary,
        surfaceContainerLowest = MnLightBgPrimary,
        surfaceContainerLow = MnLightBgPrimary,
        surfaceContainer = MnLightBgPrimary,
        surfaceContainerHigh = MnLightBgPrimary,
        surfaceContainerHighest = MnLightBgPrimary,
        error = MnLightError,
        onError = Color.White,
        outline = MnLightRingTrack,
        outlineVariant = MnLightRingTrack
    )

private val MoonDarkScheme =
    darkColorScheme(
        primary = MnDarkInteractive,
        onPrimary = MnDarkTextOnInteractive,
        primaryContainer = MnDarkAccentBg,
        onPrimaryContainer = MnDarkTextPrimary,
        secondary = MnDarkTextSecondary,
        onSecondary = MnDarkTextOnInteractive,
        secondaryContainer = MnDarkBgPrimary,
        onSecondaryContainer = MnDarkTextPrimary,
        tertiary = MnDarkInteractive,
        onTertiary = MnDarkTextOnInteractive,
        background = MnDarkBgSecondary,
        onBackground = MnDarkTextPrimary,
        surface = MnDarkBgSecondary,
        onSurface = MnDarkTextPrimary,
        surfaceVariant = MnDarkBgPrimary,
        onSurfaceVariant = MnDarkTextSecondary,
        surfaceContainerLowest = MnDarkBgPrimary,
        surfaceContainerLow = MnDarkBgPrimary,
        surfaceContainer = MnDarkBgPrimary,
        surfaceContainerHigh = MnDarkBgPrimary,
        surfaceContainerHighest = MnDarkBgPrimary,
        error = MnDarkError,
        onError = MnDarkTextOnInteractive,
        outline = MnDarkRingTrack,
        outlineVariant = MnDarkRingTrack
    )

// endregion

/**
 * Resolve the Material3 ColorScheme for the given theme and dark mode combination.
 * Internal visibility for testability.
 */
internal fun resolveColorScheme(theme: ColorTheme, darkTheme: Boolean): ColorScheme = when (theme) {
    ColorTheme.CANDLELIGHT -> if (darkTheme) CandlelightDarkScheme else CandlelightLightScheme
    ColorTheme.FOREST -> if (darkTheme) ForestDarkScheme else ForestLightScheme
    ColorTheme.MOON -> if (darkTheme) MoonDarkScheme else MoonLightScheme
}

@Composable
fun StillMomentTheme(
    colorTheme: ColorTheme = ColorTheme.DEFAULT,
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = resolveColorScheme(colorTheme, darkTheme)
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            // Safe cast for Compose Preview compatibility
            val activity = view.context as? Activity ?: return@SideEffect
            val window = activity.window
            @Suppress("DEPRECATION")
            window.statusBarColor = colorScheme.background.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = colorScheme.background.toArgb()
            val isLightAppearance = !darkTheme
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = isLightAppearance
                isAppearanceLightNavigationBars = isLightAppearance
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = StillMomentTypography,
        content = content
    )
}

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
