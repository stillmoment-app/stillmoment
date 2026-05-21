package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import com.stillmoment.R

// region Font Families

/**
 * Newsreader 16pt Optical Size — Serif fuer Display, Headlines, Body-Display.
 *
 * Enthaelt zwei Cuts (Light + Regular). Italic ist eine eigene Familie
 * ([NewsreaderItalicFontFamily]), damit Compose nicht synthetisch schraegt.
 *
 * Bei aktivem System-Bold-Text wechselt der Cut innerhalb dieser Familie von
 * Light auf Regular — siehe [TextStyle.effectiveWeight].
 */
val NewsreaderFontFamily = FontFamily(
    Font(resId = R.font.newsreader_light, weight = FontWeight.Light),
    Font(resId = R.font.newsreader_regular, weight = FontWeight.Normal),
)

/**
 * Newsreader Italic — eigene Familie, damit der Italic-Schnitt aus dem
 * Bundle gewaehlt wird statt einer synthetischen Schraegstellung der Roman-
 * Glyphen.
 */
val NewsreaderItalicFontFamily = FontFamily(
    Font(resId = R.font.newsreader_italic, weight = FontWeight.Normal, style = FontStyle.Italic),
)

/**
 * Geist — Sans fuer UI, Labels, Werte. Vier Cuts (Light, Regular, Medium,
 * SemiBold). SemiBold wird ausschliesslich beim Bold-Text-Bump von
 * [TextStyle.bodyEmphasis] (Geist Medium → SemiBold) verwendet.
 */
val GeistFontFamily = FontFamily(
    Font(resId = R.font.geist_light, weight = FontWeight.Light),
    Font(resId = R.font.geist_regular, weight = FontWeight.Normal),
    Font(resId = R.font.geist_medium, weight = FontWeight.Medium),
    Font(resId = R.font.geist_semibold, weight = FontWeight.SemiBold),
)

// endregion

// region TextStyle Token Enum (Typografie 2.1)

/**
 * Die zehn Tokens des Typografie-Systems.
 *
 * Pendant zu iOS' `TextStyle.swift` (Quelle: `handoffs/Typografie 2.1 - Plan.html`).
 * Reihenfolge folgt der Plan-Tabelle (Display → Eyebrow). Jeder Token bindet
 * Schriftfamilie, Gewicht und Basis-Groesse — Italic ist eine eigene Rolle
 * ([bodyItalic]), kein orthogonaler Modifier.
 *
 * **Naming-Hinweis:** `TextStyle` kollidiert mit `androidx.compose.ui.text.TextStyle`.
 * In Dateien, die beide brauchen, wird unser Token via
 * `import com.stillmoment.presentation.ui.theme.TextStyle as TextToken` importiert.
 *
 * @property baseSize Basis-Groesse in sp bei System-Font-Scale 1.0. `sp` skaliert
 *   automatisch mit dem System-Font-Scale-Setting.
 * @property family Schriftfamilie (Newsreader / Newsreader-Italic / Geist).
 * @property weight Default-Gewicht. Bei aktivem Bold-Text-Setting wird der
 *   Cut ueber [effectiveWeight] eine Stufe schwerer gemappt.
 * @property style Default-Style (Italic nur bei `.bodyItalic`).
 * @property tracking Letter-Spacing. Default 0; nur Tokens mit bewusstem
 *   Tracking-Bedarf weichen ab.
 * @property uppercase Nur `.eyebrow` ist tracked caps.
 */
@Suppress("EnumNaming", "EnumEntryName")
enum class TextStyle(
    val baseSize: TextUnit,
    val family: FontFamily,
    val weight: FontWeight,
    val style: FontStyle,
    val tracking: TextUnit,
    val uppercase: Boolean,
) {
    /** Container-relativ — Timer-Countdown, Dial-Value. Siehe `DisplayNumeral`. */
    display(
        baseSize = 88.sp,
        family = NewsreaderFontFamily,
        weight = FontWeight.Light,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Newsreader Light, .largeTitle-Basis — Player-Track-Title, Cover-Headlines. */
    title(
        baseSize = 30.sp,
        family = NewsreaderFontFamily,
        weight = FontWeight.Light,
        style = FontStyle.Normal,
        tracking = (-0.4).sp,
        uppercase = false,
    ),

    /** Newsreader Light, .title-Basis — Screen-Header (Large-Title, Inline-NavBar). */
    screenTitle(
        baseSize = 26.sp,
        family = NewsreaderFontFamily,
        weight = FontWeight.Light,
        style = FontStyle.Normal,
        tracking = (-0.4).sp,
        uppercase = false,
    ),

    /** Newsreader Light, .title3-Basis — List-Section-Title, Dialog-Title. */
    section(
        baseSize = 20.sp,
        family = NewsreaderFontFamily,
        weight = FontWeight.Light,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Geist Regular, .body-Basis — Standardtext, List-Row-Title, Settings-Label. */
    body(
        baseSize = 17.sp,
        family = GeistFontFamily,
        weight = FontWeight.Normal,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Geist Medium, .body-Basis — primaere CTAs, Tab-Bar-aktiv, List-Action-Label. */
    bodyEmphasis(
        baseSize = 17.sp,
        family = GeistFontFamily,
        weight = FontWeight.Medium,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Newsreader Italic, .body-Basis — Lehrer-Name, Eigennamen, Akzent (`<em>`). */
    bodyItalic(
        baseSize = 17.sp,
        family = NewsreaderItalicFontFamily,
        weight = FontWeight.Normal,
        style = FontStyle.Italic,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Geist Regular, .subheadline-Basis — List-Subtitle, Settings-Description. */
    caption(
        baseSize = 14.sp,
        family = GeistFontFamily,
        weight = FontWeight.Normal,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Geist Regular, .caption2-Basis — Timestamps, Units, Card-Labels. */
    micro(
        baseSize = 11.sp,
        family = GeistFontFamily,
        weight = FontWeight.Normal,
        style = FontStyle.Normal,
        tracking = 0.sp,
        uppercase = false,
    ),

    /** Geist Regular UPPER tracked, .caption2-Basis — Tracked-Caps-Labels. */
    eyebrow(
        baseSize = 11.sp,
        family = GeistFontFamily,
        weight = FontWeight.Normal,
        style = FontStyle.Normal,
        tracking = 2.4.sp,
        uppercase = true,
    );

    /**
     * Effektives Gewicht bei aktivem System-Bold-Text-Setting.
     *
     * Mapping (analog iOS `LegibilityWeight.bold`):
     * - Geist Regular → Geist Medium
     * - Geist Medium → Geist SemiBold
     * - Newsreader Light → Newsreader Regular
     * - Italic bleibt Italic
     */
    fun effectiveWeight(boldTextEnabled: Boolean): FontWeight {
        if (!boldTextEnabled) return weight
        return when (this) {
            body, caption, micro, eyebrow -> FontWeight.Medium
            bodyEmphasis -> FontWeight.SemiBold
            display, title, screenTitle, section -> FontWeight.Normal
            bodyItalic -> FontWeight.Normal
        }
    }

    /**
     * Effektive Familie bei aktivem System-Bold-Text-Setting.
     *
     * Familie wechselt **nicht** zwischen Cuts derselben Familie. Newsreader
     * (Light + Regular) und Geist (Light, Regular, Medium, SemiBold) sind als
     * `FontFamily` mit mehreren Cuts gebaut — Compose waehlt den passenden
     * Cut anhand des effektiven [FontWeight]s. `bodyItalic` bleibt in der
     * Italic-Familie, damit der Italic-Schnitt nicht durch einen Roman-Schnitt
     * ersetzt wird.
     *
     * Bewusst als Funktion (statt direktes `family`-Lookup), damit zukuenftige
     * Familien-Wechsel an einer Stelle ergaenzbar bleiben.
     */
    @Suppress("UNUSED_PARAMETER")
    fun effectiveFamily(boldTextEnabled: Boolean): FontFamily = family
}

// endregion
