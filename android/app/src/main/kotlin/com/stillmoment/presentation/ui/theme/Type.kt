package com.stillmoment.presentation.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle as ComposeTextStyle
import androidx.compose.ui.unit.TextUnit
import com.stillmoment.presentation.ui.theme.TextStyle as TextToken

// region TypographyRole (Bridge — deprecated, wird in finalem Migrations-Schritt geloescht)

/**
 * Semantic typography roles for the app's design system.
 *
 * **Status:** Bridge zur Typografie-2.1-Migration. Mapping zu den zehn neuen
 * Tokens ([TextStyle]) erfolgt unten via [TypographyRole.token] und
 * [TypographyRole.colorRole]. Aufrufstellen werden schrittweise auf die neue
 * API umgestellt; danach wird `TypographyRole` ersatzlos geloescht.
 */
@Deprecated(
    message = "Use TextStyle (10-token system) instead. Migration in progress (shared-099).",
    replaceWith = ReplaceWith("TextStyle", imports = ["com.stillmoment.presentation.ui.theme.TextStyle"])
)
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
    EditCaption,

    // Dialog (modal cards, e.g. download progress)
    DialogTitle,
    DialogBody,

    // Timer Idle Dial (shared-086 / shared-089)
    DialValue,
    DialUnit
}

// endregion

// region Mapping zu Typografie 2.1

/**
 * Mapping-Tabelle (Plan shared-099-android, Section "Aufrufstellen-Migration").
 * Quelle der Wahrheit fuer die Migration. Bridge bis [TypographyRole] geloescht
 * ist.
 */
@Suppress("DEPRECATION", "ComplexMethod")
internal val TypographyRole.token: TextToken
    get() = when (this) {
        // Display-Numerik — Mapping vorhanden, aber Aufrufer sollte DisplayNumeralText() nutzen.
        TypographyRole.TimerCountdown,
        TypographyRole.TimerRunning,
        TypographyRole.PlayerCountdown,
        TypographyRole.DialValue -> TextToken.display
        // Headings
        TypographyRole.ScreenTitle -> TextToken.screenTitle
        TypographyRole.SectionTitle -> TextToken.section
        TypographyRole.PlayerTitle -> TextToken.title
        TypographyRole.DialogTitle -> TextToken.section
        // Body
        TypographyRole.BodyPrimary,
        TypographyRole.BodySecondary,
        TypographyRole.SettingsLabel,
        TypographyRole.ListTitle,
        TypographyRole.ListBody -> TextToken.body
        TypographyRole.EditLabel,
        TypographyRole.ListActionLabel -> TextToken.bodyEmphasis
        // Italic
        TypographyRole.PlayerTeacher -> TextToken.bodyItalic
        // Caption
        TypographyRole.Caption,
        TypographyRole.SettingsDescription,
        TypographyRole.ListSubtitle,
        TypographyRole.EditCaption,
        TypographyRole.DialogBody -> TextToken.caption
        // Micro / Eyebrow
        TypographyRole.PlayerTimestamp -> TextToken.micro
        TypographyRole.ListSectionTitle,
        TypographyRole.DialUnit -> TextToken.eyebrow
    }

/**
 * Semantic color roles for typography.
 */
internal enum class ThemeColorRole {
    TextPrimary,
    TextSecondary,
    Interactive
}

/**
 * Mapping `TypographyRole → ThemeColorRole`. Bridge bis Migration komplett.
 */
@Suppress("DEPRECATION")
internal val TypographyRole.colorRole: ThemeColorRole
    get() = when (this) {
        TypographyRole.TimerCountdown,
        TypographyRole.TimerRunning,
        TypographyRole.ScreenTitle,
        TypographyRole.SectionTitle,
        TypographyRole.BodyPrimary,
        TypographyRole.SettingsLabel,
        TypographyRole.PlayerTitle,
        TypographyRole.PlayerCountdown,
        TypographyRole.ListTitle,
        TypographyRole.ListSectionTitle,
        TypographyRole.ListActionLabel,
        TypographyRole.EditLabel,
        TypographyRole.DialogTitle,
        TypographyRole.DialValue -> ThemeColorRole.TextPrimary
        TypographyRole.BodySecondary,
        TypographyRole.Caption,
        TypographyRole.SettingsDescription,
        TypographyRole.PlayerTimestamp,
        TypographyRole.ListSubtitle,
        TypographyRole.ListBody,
        TypographyRole.EditCaption,
        TypographyRole.DialogBody,
        TypographyRole.DialUnit -> ThemeColorRole.TextSecondary
        TypographyRole.PlayerTeacher -> ThemeColorRole.Interactive
    }

/**
 * Resolves a [ThemeColorRole] to a concrete color from the current [ColorScheme].
 */
internal fun ThemeColorRole.resolve(colorScheme: ColorScheme): Color = when (this) {
    ThemeColorRole.TextPrimary -> colorScheme.onSurface
    ThemeColorRole.TextSecondary -> colorScheme.onSurfaceVariant
    ThemeColorRole.Interactive -> colorScheme.primary
}

// endregion

// region Composable Extensions (Bridge)

/**
 * Resolves this role to a [ComposeTextStyle] using the new Typografie-2.1 system.
 *
 * @param sizeOverride Optional size override for responsive layouts. Pass
 *   [TextUnit.Unspecified] (default) to use the token's default size.
 */
@Composable
@ReadOnlyComposable
@Suppress("DEPRECATION")
fun TypographyRole.textStyle(sizeOverride: TextUnit = TextUnit.Unspecified): ComposeTextStyle {
    val composeStyle = this.token.toComposeTextStyle()
    return if (sizeOverride != TextUnit.Unspecified) {
        composeStyle.copy(fontSize = sizeOverride)
    } else {
        composeStyle
    }
}

/**
 * Resolves this role's default text color from the current theme.
 */
@Composable
@ReadOnlyComposable
@Suppress("DEPRECATION")
fun TypographyRole.textColor(): Color = this.colorRole.resolve(MaterialTheme.colorScheme)

// endregion

// region Material Typography (extends MaterialTheme with Newsreader/Geist)

/**
 * Material 3 typography slot mapping → Typografie-2.1-Tokens.
 *
 * Pendant zur iOS-Typografie-Strategie: Material-Komponenten (Button,
 * TextField, AlertDialog) lesen aus `MaterialTheme.typography`. Damit sie
 * automatisch Newsreader/Geist sprechen, statt in jedem Composable
 * ueberschrieben zu werden, mapped dieser Block 15 Material-Slots auf
 * unsere zehn Tokens.
 *
 * Mapping (Plan shared-099-android, Annahmen-Block):
 * - displayLarge/Medium/Small → title
 * - headlineLarge/Medium/Small → screenTitle
 * - titleLarge/Medium/Small → section
 * - bodyLarge/Medium → body
 * - bodySmall → caption
 * - labelLarge → bodyEmphasis
 * - labelMedium/Small → micro
 *
 * Diese Bindung ist statisch — sie reagiert nicht auf das Bold-Text-Setting
 * (Material's Typography ist nicht Composable). Bold-Text greift weiterhin
 * fuer alle Texte, die unsere [TextStyle.toComposeTextStyle]-API direkt
 * nutzen.
 */
val StillMomentTypography: Typography = buildTypography()

private fun buildTypography(): Typography {
    fun slot(token: TextToken) = ComposeTextStyle(
        fontFamily = token.family,
        fontSize = token.baseSize,
        fontWeight = token.weight,
        fontStyle = token.style,
        letterSpacing = token.tracking,
    )
    return Typography(
        displayLarge = slot(TextToken.title),
        displayMedium = slot(TextToken.title),
        displaySmall = slot(TextToken.title),
        headlineLarge = slot(TextToken.screenTitle),
        headlineMedium = slot(TextToken.screenTitle),
        headlineSmall = slot(TextToken.screenTitle),
        titleLarge = slot(TextToken.section),
        titleMedium = slot(TextToken.section),
        titleSmall = slot(TextToken.section),
        bodyLarge = slot(TextToken.body),
        bodyMedium = slot(TextToken.body),
        bodySmall = slot(TextToken.caption),
        labelLarge = slot(TextToken.bodyEmphasis),
        labelMedium = slot(TextToken.micro),
        labelSmall = slot(TextToken.micro),
    )
}

// endregion
