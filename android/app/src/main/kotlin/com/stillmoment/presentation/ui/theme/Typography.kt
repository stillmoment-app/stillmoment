package com.stillmoment.presentation.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle as ComposeTextStyle
import com.stillmoment.presentation.ui.theme.TextStyle as TextToken

// region Material Typography (extends MaterialTheme with Newsreader/Geist)

/**
 * Material 3 Typography-Slot-Mapping → Typografie-2.1-Tokens.
 *
 * Pendant zur iOS-Typografie-Strategie: Material-Komponenten (Button,
 * TextField, AlertDialog) lesen aus `MaterialTheme.typography`. Damit sie
 * automatisch Newsreader/Geist sprechen — statt in jedem Composable
 * ueberschrieben zu werden — mapped dieser Block 15 Material-Slots auf die
 * zehn Tokens des Typografie-Systems.
 *
 * Mapping (Plan shared-099-android, Annahmen-Block):
 * - `displayLarge` / `displayMedium` / `displaySmall` → `.title`
 * - `headlineLarge` / `headlineMedium` / `headlineSmall` → `.screenTitle`
 * - `titleLarge` / `titleMedium` / `titleSmall` → `.section`
 * - `bodyLarge` / `bodyMedium` → `.body`
 * - `bodySmall` → `.caption`
 * - `labelLarge` → `.bodyEmphasis`
 * - `labelMedium` / `labelSmall` → `.micro`
 *
 * Diese Bindung ist statisch — sie reagiert nicht auf das Bold-Text-Setting
 * (Material's `Typography` ist kein `Composable`). Bold-Text greift weiterhin
 * fuer alle Texte, die die [TextStyle.toComposeTextStyle]-API direkt nutzen.
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
