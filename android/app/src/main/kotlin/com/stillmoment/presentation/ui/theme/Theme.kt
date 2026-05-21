@file:Suppress("MatchingDeclarationName")

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
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Additional semantic colors not covered by Material 3 ColorScheme.
 * These map to iOS ThemeColors roles that have no Material 3 equivalent.
 */
data class StillMomentColors(
    /**
     * Warm interactive/accent color — the single source of truth for warm
     * accents that drive the app (CTAs, ring arcs, lotus petals, droplet core).
     * Matches iOS `theme.interactive`. Direct alias of `MaterialTheme.colorScheme.primary`,
     * exposed here so call sites can stay in the `LocalStillMomentColors` vocabulary.
     */
    val interactive: Color,
    /**
     * Primary text color (warm ink). Matches iOS `theme.textPrimary`. Alias of
     * `MaterialTheme.colorScheme.onSurface`, exposed here so headlines/body copy
     * stay in the `LocalStillMomentColors` vocabulary.
     */
    val textPrimary: Color,
    /** Timer ring progress color */
    val progress: Color,
    /** Toggle/Slider inactive track color (WCAG >= 3:1 vs cardBackground) */
    val controlTrack: Color,
    /** Card background color (Light ~= bgPrimary, Dark = own value) */
    val cardBackground: Color,
    /** Card border: warm-tinted in both modes (shared-094) */
    val cardBorder: Color,
    /**
     * Generic warm divider in the accent family (shared-094).
     * Used between cards of the same teacher block and as the settings-list divider.
     */
    val divider: Color,
    /** Divider color for the flat settings list (shared-089/094 — alias of divider) */
    val settingsDivider: Color,
    /** Accent color for the value text in the flat settings list (shared-089) */
    val settingsValueAccent: Color,
    /** Active arc color of the BreathDial picker (shared-086) */
    val dialActiveArc: Color,
    /** Halo color (with alpha) around the BreathDial droplet (shared-086) */
    val dialDropletHalo: Color,
    /** Core fill color of the BreathDial droplet (shared-086) */
    val dialDropletCore: Color,
    /** Top stop of the plastic play-button gradient (shared-094) */
    val playGradientTop: Color,
    /** Bottom stop of the plastic play-button gradient (shared-094) */
    val playGradientBot: Color,
    /** Foreground (text + icon) color used on top of `interactive` / play gradient (shared-094) */
    val textOnInteractive: Color,
    /** Warm contact/body shadow color for lifted cards in light mode (shared-094) */
    val cardShadow: Color,
    /** Tab bar background — matches cardBackground (shared-094) */
    val tabBarBackground: Color,
    /**
     * Accent banner background — interactive @ alpha 0.10 (shared-094).
     * Vorlage fuer das spaetere Android-Pendant zu shared-039b.
     */
    val accentBannerBackground: Color,
    /** Accent banner border — interactive @ alpha 0.28 (shared-094) */
    val accentBannerBorder: Color,
    /** Accent bubble background — interactive @ alpha 0.18 (shared-094) */
    val accentBubbleBackground: Color
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
        interactive = SmLightInteractive,
        textPrimary = SmLightTextPrimary,
        divider = SmLightDivider,
        playGradientTop = SmLightPlayGradientTop,
        playGradientBot = SmLightPlayGradientBot,
        cardShadow = SmLightCardShadow,
        textOnInteractive = SmLightTextOnInteractive
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
        interactive = SmDarkInteractive,
        textPrimary = SmDarkTextPrimary,
        divider = SmDarkDivider,
        playGradientTop = SmDarkPlayGradientTop,
        playGradientBot = SmDarkPlayGradientBot,
        cardShadow = SmDarkCardShadow,
        textOnInteractive = SmDarkTextOnInteractive
    )
} else {
    buildStillMomentColors(
        progress = SmLightProgress,
        controlTrack = SmLightControlTrack,
        cardBackground = SmLightCardBackground,
        cardBorder = SmLightCardBorder,
        interactive = SmLightInteractive,
        textPrimary = SmLightTextPrimary,
        divider = SmLightDivider,
        playGradientTop = SmLightPlayGradientTop,
        playGradientBot = SmLightPlayGradientBot,
        cardShadow = SmLightCardShadow,
        textOnInteractive = SmLightTextOnInteractive
    )
}

/**
 * Builds [StillMomentColors] with derived shared-086/089/094 tokens. Centralised so the
 * derivation rules (alpha for divider/halo, primary as accent/arc/core, accent banner
 * alphas 0.10/0.28/0.18) live in one place and stay consistent across both variants.
 */
@Suppress("LongParameterList") // Theme color builder bundles all source values explicitly
private fun buildStillMomentColors(
    progress: Color,
    controlTrack: Color,
    cardBackground: Color,
    cardBorder: Color,
    interactive: Color,
    textPrimary: Color,
    divider: Color,
    playGradientTop: Color,
    playGradientBot: Color,
    cardShadow: Color,
    textOnInteractive: Color
): StillMomentColors = StillMomentColors(
    interactive = interactive,
    textPrimary = textPrimary,
    progress = progress,
    controlTrack = controlTrack,
    cardBackground = cardBackground,
    cardBorder = cardBorder,
    divider = divider,
    // shared-094: settingsDivider and the generic divider intentionally share Hue + Alpha.
    settingsDivider = divider,
    settingsValueAccent = interactive,
    dialActiveArc = interactive,
    dialDropletHalo = interactive.copy(alpha = 0.18f),
    dialDropletCore = interactive,
    playGradientTop = playGradientTop,
    playGradientBot = playGradientBot,
    textOnInteractive = textOnInteractive,
    cardShadow = cardShadow,
    tabBarBackground = cardBackground,
    accentBannerBackground = interactive.copy(alpha = 0.10f),
    accentBannerBorder = interactive.copy(alpha = 0.28f),
    accentBubbleBackground = interactive.copy(alpha = 0.18f)
)

/**
 * Still Moment Theme — single curated palette with Light + Dark variants.
 * Color values taken 1:1 from iOS ThemeColors+Palettes.swift.
 */

// region Color Schemes

private val StillMomentLightScheme =
    lightColorScheme(
        primary = SmLightInteractive,
        // shared-094: warm cream on the play gradient (was pure white before).
        onPrimary = SmLightTextOnInteractive,
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
