package com.stillmoment.presentation.ui.theme

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Still Moment Theme - Warm Earth Tones with Material 3
 * Light mode only (matching iOS design).
 */

private val StillMomentColorScheme = lightColorScheme(
    primary = Terracotta,
    onPrimary = Color.White,
    primaryContainer = PaleApricot,
    onPrimaryContainer = WarmBlack,
    secondary = WarmGray,
    onSecondary = Color.White,
    secondaryContainer = WarmCream,
    onSecondaryContainer = WarmBlack,
    tertiary = Terracotta,
    onTertiary = Color.White,
    background = WarmSand,
    onBackground = WarmBlack,
    surface = WarmSand,
    onSurface = WarmBlack,
    surfaceVariant = WarmCream,
    onSurfaceVariant = WarmGray,
    error = WarmError,
    onError = Color.White,
    outline = WarmGray,
    outlineVariant = RingBackground
)

@Composable
fun StillMomentTheme(
    content: @Composable () -> Unit
) {
    val colorScheme = StillMomentColorScheme
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            // Safe cast for Paparazzi/preview compatibility
            val activity = view.context as? Activity ?: return@SideEffect
            val window = activity.window
            @Suppress("DEPRECATION")
            window.statusBarColor = colorScheme.background.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = true
                isAppearanceLightNavigationBars = true
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
 * Vertical gradient from WarmCream via WarmSand to PaleApricot.
 */
@Composable
fun WarmGradientBackground(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        WarmCream,  // top
                        WarmSand,   // middle
                        PaleApricot // bottom
                    )
                )
            )
    )
}
