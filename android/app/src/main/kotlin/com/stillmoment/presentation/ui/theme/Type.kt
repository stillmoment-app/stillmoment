package com.stillmoment.presentation.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import com.stillmoment.R

// region Nunito Font Family

/**
 * Nunito - rounded sans-serif font for cross-platform consistency with iOS (SF Rounded).
 * Variable font with weight axis, providing all weights from Thin (100) to Bold (700).
 */
@OptIn(ExperimentalTextApi::class)
val NunitoFontFamily = FontFamily(
    Font(
        resId = R.font.nunito,
        weight = FontWeight.Thin,
        variationSettings = FontVariation.Settings(FontVariation.weight(100))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.ExtraLight,
        variationSettings = FontVariation.Settings(FontVariation.weight(200))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.Light,
        variationSettings = FontVariation.Settings(FontVariation.weight(300))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.Normal,
        variationSettings = FontVariation.Settings(FontVariation.weight(400))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.Medium,
        variationSettings = FontVariation.Settings(FontVariation.weight(500))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.SemiBold,
        variationSettings = FontVariation.Settings(FontVariation.weight(600))
    ),
    Font(
        resId = R.font.nunito,
        weight = FontWeight.Bold,
        variationSettings = FontVariation.Settings(FontVariation.weight(700))
    )
)

// endregion

// region Typography Role

/**
 * Semantic typography roles for the app's design system.
 *
 * Each role defines font size, weight, and text color in one place.
 * Dark mode font weight compensation is applied automatically - views never
 * need to check dark mode state for font purposes.
 *
 * Matches iOS TypographyRole for cross-platform consistency.
 */
enum class TypographyRole {
    // Timer
    TimerCountdown,
    TimerRunning,

    // Headings
    ScreenTitle,
    SectionTitle,

    // Body
    BodyPrimary,
    BodySecondary,
    Caption,

    // Settings
    SettingsLabel,
    SettingsDescription,

    // Player
    PlayerTitle,
    PlayerTeacher,
    PlayerTimestamp,
    PlayerCountdown,

    // List
    ListTitle,
    ListSubtitle,
    ListBody,
    ListSectionTitle,
    ListActionLabel,

    // Edit
    EditLabel,
    EditCaption
}

// endregion

// region Font Spec (Single Source of Truth)

/**
 * Defines the base font specification for a typography role.
 * Internal visibility for unit test access.
 */
internal data class FontSpec(
    val size: TextUnit,
    val weight: FontWeight,
)

/**
 * The base font specification for each role.
 * Sizes match iOS for cross-platform visual consistency.
 */
internal val TypographyRole.fontSpec: FontSpec
    get() = when (this) {
        // Timer - ultra-thin for large numerals
        TypographyRole.TimerCountdown -> FontSpec(100.sp, FontWeight.Thin)
        TypographyRole.TimerRunning -> FontSpec(60.sp, FontWeight.ExtraLight)
        // Headings
        TypographyRole.ScreenTitle -> FontSpec(28.sp, FontWeight.Light)
        TypographyRole.SectionTitle -> FontSpec(20.sp, FontWeight.Light)
        // Body
        TypographyRole.BodyPrimary -> FontSpec(16.sp, FontWeight.Normal)
        TypographyRole.BodySecondary -> FontSpec(15.sp, FontWeight.Light)
        TypographyRole.Caption -> FontSpec(12.sp, FontWeight.Normal)
        // Settings
        TypographyRole.SettingsLabel -> FontSpec(17.sp, FontWeight.Normal)
        TypographyRole.SettingsDescription -> FontSpec(13.sp, FontWeight.Normal)
        // Player
        TypographyRole.PlayerTitle -> FontSpec(28.sp, FontWeight.SemiBold)
        TypographyRole.PlayerTeacher -> FontSpec(20.sp, FontWeight.Medium)
        TypographyRole.PlayerTimestamp -> FontSpec(12.sp, FontWeight.Normal)
        TypographyRole.PlayerCountdown -> FontSpec(32.sp, FontWeight.Light)
        // List
        TypographyRole.ListTitle -> FontSpec(16.sp, FontWeight.Medium)
        TypographyRole.ListSubtitle -> FontSpec(12.sp, FontWeight.Normal)
        TypographyRole.ListBody -> FontSpec(14.sp, FontWeight.Normal)
        TypographyRole.ListSectionTitle -> FontSpec(14.sp, FontWeight.SemiBold)
        TypographyRole.ListActionLabel -> FontSpec(14.sp, FontWeight.Medium)
        // Edit
        TypographyRole.EditLabel -> FontSpec(14.sp, FontWeight.Medium)
        TypographyRole.EditCaption -> FontSpec(12.sp, FontWeight.Normal)
    }

// endregion

// region Text Color Mapping

/**
 * Semantic color roles for typography.
 * Internal visibility for unit test access.
 */
internal enum class ThemeColorRole {
    TextPrimary,
    TextSecondary,
    Interactive
}

/**
 * Maps each typography role to its semantic text color.
 * Mirrors iOS TypographyRole.textColor mapping.
 */
internal val TypographyRole.colorRole: ThemeColorRole
    get() = when (this) {
        TypographyRole.TimerCountdown,
        TypographyRole.TimerRunning -> ThemeColorRole.TextPrimary
        TypographyRole.ScreenTitle,
        TypographyRole.SectionTitle -> ThemeColorRole.TextPrimary
        TypographyRole.BodyPrimary -> ThemeColorRole.TextPrimary
        TypographyRole.BodySecondary,
        TypographyRole.Caption -> ThemeColorRole.TextSecondary
        TypographyRole.SettingsLabel -> ThemeColorRole.TextPrimary
        TypographyRole.SettingsDescription -> ThemeColorRole.TextSecondary
        TypographyRole.PlayerTitle -> ThemeColorRole.TextPrimary
        TypographyRole.PlayerTeacher -> ThemeColorRole.Interactive
        TypographyRole.PlayerTimestamp -> ThemeColorRole.TextSecondary
        TypographyRole.PlayerCountdown -> ThemeColorRole.TextPrimary
        TypographyRole.ListTitle,
        TypographyRole.ListSectionTitle -> ThemeColorRole.TextPrimary
        TypographyRole.ListSubtitle,
        TypographyRole.ListBody -> ThemeColorRole.TextSecondary
        TypographyRole.ListActionLabel -> ThemeColorRole.TextPrimary
        TypographyRole.EditLabel -> ThemeColorRole.TextPrimary
        TypographyRole.EditCaption -> ThemeColorRole.TextSecondary
    }

/**
 * Resolves a [ThemeColorRole] to a concrete color from the current [ColorScheme].
 */
internal fun ThemeColorRole.resolve(colorScheme: ColorScheme) = when (this) {
    ThemeColorRole.TextPrimary -> colorScheme.onSurface
    ThemeColorRole.TextSecondary -> colorScheme.onSurfaceVariant
    ThemeColorRole.Interactive -> colorScheme.primary
}

// endregion

// region Dark Mode Halation Compensation

/**
 * Returns one step heavier weight in dark mode to compensate for halation
 * (light text on dark backgrounds appears thinner than dark text on light backgrounds).
 *
 * Compensation steps:
 * - Thin (100) -> ExtraLight (200)
 * - ExtraLight (200) -> Light (300)
 * - Light (300) -> Normal (400)
 * - Normal (400) -> Medium (500)
 * - Medium+ -> unchanged (already heavy enough)
 */
internal fun FontWeight.darkModeCompensated(isDark: Boolean): FontWeight {
    if (!isDark) return this
    return when (this) {
        FontWeight.Thin -> FontWeight.ExtraLight
        FontWeight.ExtraLight -> FontWeight.Light
        FontWeight.Light -> FontWeight.Normal
        FontWeight.Normal -> FontWeight.Medium
        else -> this
    }
}

// endregion

// region Composable Extensions

/**
 * Resolves this role to a [TextStyle] with dark mode halation compensation.
 *
 * @param sizeOverride Optional size override for responsive layouts (e.g. compact timer).
 *   Pass [TextUnit.Unspecified] (default) to use the role's default size.
 */
@Composable
fun TypographyRole.textStyle(sizeOverride: TextUnit = TextUnit.Unspecified): TextStyle {
    val isDark = LocalIsDarkTheme.current
    val spec = this.fontSpec
    val actualSize = if (sizeOverride != TextUnit.Unspecified) sizeOverride else spec.size
    return TextStyle(
        fontFamily = NunitoFontFamily,
        fontSize = actualSize,
        fontWeight = spec.weight.darkModeCompensated(isDark),
    )
}

/**
 * Resolves this role's default text color from the current theme.
 */
@Composable
fun TypographyRole.textColor(): androidx.compose.ui.graphics.Color {
    return this.colorRole.resolve(MaterialTheme.colorScheme)
}

// endregion

// region Material Typography (extends MaterialTheme with Nunito)

/**
 * Still Moment Typography for MaterialTheme integration.
 * Uses Nunito rounded font for cross-platform consistency with iOS (SF Rounded).
 *
 * Note: Views should prefer TypographyRole for text styling.
 * This Typography is provided for Material components (TextField, Button, etc.)
 * that read from MaterialTheme.typography internally.
 */
val StillMomentTypography =
    Typography(
        displayLarge =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Light,
            fontSize = 72.sp,
            lineHeight = 80.sp,
            letterSpacing = (-0.5).sp
        ),
        displayMedium =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Light,
            fontSize = 56.sp,
            lineHeight = 64.sp,
            letterSpacing = 0.sp
        ),
        displaySmall =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Normal,
            fontSize = 36.sp,
            lineHeight = 44.sp,
            letterSpacing = 0.sp
        ),
        headlineLarge =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.SemiBold,
            fontSize = 32.sp,
            lineHeight = 40.sp,
            letterSpacing = 0.sp
        ),
        headlineMedium =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.SemiBold,
            fontSize = 28.sp,
            lineHeight = 36.sp,
            letterSpacing = 0.sp
        ),
        headlineSmall =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.SemiBold,
            fontSize = 24.sp,
            lineHeight = 32.sp,
            letterSpacing = 0.sp
        ),
        titleLarge =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 22.sp,
            lineHeight = 28.sp,
            letterSpacing = 0.sp
        ),
        titleMedium =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            letterSpacing = 0.15.sp
        ),
        titleSmall =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 14.sp,
            lineHeight = 20.sp,
            letterSpacing = 0.1.sp
        ),
        bodyLarge =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Normal,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            letterSpacing = 0.5.sp
        ),
        bodyMedium =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Normal,
            fontSize = 14.sp,
            lineHeight = 20.sp,
            letterSpacing = 0.25.sp
        ),
        bodySmall =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Normal,
            fontSize = 12.sp,
            lineHeight = 16.sp,
            letterSpacing = 0.4.sp
        ),
        labelLarge =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 14.sp,
            lineHeight = 20.sp,
            letterSpacing = 0.1.sp
        ),
        labelMedium =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 12.sp,
            lineHeight = 16.sp,
            letterSpacing = 0.5.sp
        ),
        labelSmall =
        TextStyle(
            fontFamily = NunitoFontFamily,
            fontWeight = FontWeight.Medium,
            fontSize = 11.sp,
            lineHeight = 16.sp,
            letterSpacing = 0.5.sp
        )
    )

// endregion
