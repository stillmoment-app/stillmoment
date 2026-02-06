package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.graphics.Color
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * WCAG 2.1 AA contrast validation for all theme palettes.
 * Ensures text-on-background combinations meet minimum contrast ratios.
 *
 * Reference: https://www.w3.org/TR/WCAG21/#contrast-minimum
 * - Normal text: 4.5:1
 * - Large text (≥18pt regular or ≥14pt bold): 3:1
 */
class WCAGContrastTest {

    companion object {
        private const val NORMAL_TEXT_MIN_CONTRAST = 4.5
    }

    // region WCAG Contrast Calculation

    /** Linearize a single sRGB channel per WCAG 2.1. */
    private fun linearize(channel: Float): Double {
        val c = channel.toDouble()
        return if (c <= 0.04045) c / 12.92 else ((c + 0.055) / 1.055).pow(2.4)
    }

    /** Relative luminance per WCAG 2.1. */
    private fun relativeLuminance(color: Color): Double = 0.2126 * linearize(color.red) +
        0.7152 * linearize(color.green) +
        0.0722 * linearize(color.blue)

    /** Contrast ratio per WCAG 2.1. */
    private fun contrastRatio(foreground: Color, background: Color): Double {
        val lumFg = relativeLuminance(foreground)
        val lumBg = relativeLuminance(background)
        val lighter = max(lumFg, lumBg)
        val darker = min(lumFg, lumBg)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // endregion

    // region Assertion Helper

    private fun assertContrast(
        foreground: Color,
        background: Color,
        minimumRatio: Double,
        foregroundName: String,
        backgroundName: String,
        palette: String
    ) {
        val ratio = contrastRatio(foreground, background)
        assertTrue(ratio >= minimumRatio) {
            "$palette: $foregroundName on $backgroundName — " +
                "contrast ${"%.2f".format(ratio)}:1, " +
                "minimum ${"%.1f".format(minimumRatio)}:1"
        }
    }

    /** Palette color holder matching iOS ThemeColors semantic roles. */
    private data class PaletteColors(
        val name: String,
        val textPrimary: Color,
        val textSecondary: Color,
        val textOnInteractive: Color,
        val interactive: Color,
        val backgroundPrimary: Color,
        val backgroundSecondary: Color,
        val error: Color
    )

    private fun assertAllCombinations(palette: PaletteColors) {
        // textPrimary on backgrounds (normal text → 4.5:1)
        assertContrast(
            palette.textPrimary,
            palette.backgroundPrimary,
            NORMAL_TEXT_MIN_CONTRAST,
            "textPrimary",
            "backgroundPrimary",
            palette.name
        )
        assertContrast(
            palette.textPrimary,
            palette.backgroundSecondary,
            NORMAL_TEXT_MIN_CONTRAST,
            "textPrimary",
            "backgroundSecondary",
            palette.name
        )

        // textSecondary on backgrounds (normal text → 4.5:1)
        assertContrast(
            palette.textSecondary,
            palette.backgroundPrimary,
            NORMAL_TEXT_MIN_CONTRAST,
            "textSecondary",
            "backgroundPrimary",
            palette.name
        )
        assertContrast(
            palette.textSecondary,
            palette.backgroundSecondary,
            NORMAL_TEXT_MIN_CONTRAST,
            "textSecondary",
            "backgroundSecondary",
            palette.name
        )

        // textOnInteractive on interactive (normal text → 4.5:1)
        assertContrast(
            palette.textOnInteractive,
            palette.interactive,
            NORMAL_TEXT_MIN_CONTRAST,
            "textOnInteractive",
            "interactive",
            palette.name
        )

        // interactive as text on backgroundPrimary (link color → 4.5:1)
        assertContrast(
            palette.interactive,
            palette.backgroundPrimary,
            NORMAL_TEXT_MIN_CONTRAST,
            "interactive",
            "backgroundPrimary",
            palette.name
        )

        // error on backgroundPrimary (normal text → 4.5:1)
        assertContrast(
            palette.error,
            palette.backgroundPrimary,
            NORMAL_TEXT_MIN_CONTRAST,
            "error",
            "backgroundPrimary",
            palette.name
        )
    }

    // endregion

    // region Palette definitions

    private val candlelightLight = PaletteColors(
        name = "Candlelight Light",
        textPrimary = CdLightTextPrimary,
        textSecondary = CdLightTextSecondary,
        textOnInteractive = Color.White,
        interactive = CdLightInteractive,
        backgroundPrimary = CdLightBgPrimary,
        backgroundSecondary = CdLightBgSecondary,
        error = CdLightError
    )

    private val candlelightDark = PaletteColors(
        name = "Candlelight Dark",
        textPrimary = CdDarkTextPrimary,
        textSecondary = CdDarkTextSecondary,
        textOnInteractive = CdDarkTextOnInteractive,
        interactive = CdDarkInteractive,
        backgroundPrimary = CdDarkBgPrimary,
        backgroundSecondary = CdDarkBgSecondary,
        error = CdDarkError
    )

    private val forestLight = PaletteColors(
        name = "Forest Light",
        textPrimary = FoLightTextPrimary,
        textSecondary = FoLightTextSecondary,
        textOnInteractive = FoLightTextOnInteractive,
        interactive = FoLightInteractive,
        backgroundPrimary = FoLightBgPrimary,
        backgroundSecondary = FoLightBgSecondary,
        error = FoLightError
    )

    private val forestDark = PaletteColors(
        name = "Forest Dark",
        textPrimary = FoDarkTextPrimary,
        textSecondary = FoDarkTextSecondary,
        textOnInteractive = FoDarkTextOnInteractive,
        interactive = FoDarkInteractive,
        backgroundPrimary = FoDarkBgPrimary,
        backgroundSecondary = FoDarkBgSecondary,
        error = FoDarkError
    )

    private val moonLight = PaletteColors(
        name = "Moon Light",
        textPrimary = MnLightTextPrimary,
        textSecondary = MnLightTextSecondary,
        textOnInteractive = MnLightTextOnInteractive,
        interactive = MnLightInteractive,
        backgroundPrimary = MnLightBgPrimary,
        backgroundSecondary = MnLightBgSecondary,
        error = MnLightError
    )

    private val moonDark = PaletteColors(
        name = "Moon Dark",
        textPrimary = MnDarkTextPrimary,
        textSecondary = MnDarkTextSecondary,
        textOnInteractive = MnDarkTextOnInteractive,
        interactive = MnDarkInteractive,
        backgroundPrimary = MnDarkBgPrimary,
        backgroundSecondary = MnDarkBgSecondary,
        error = MnDarkError
    )

    // endregion

    // region Tests per Palette

    @Nested
    inner class CandlelightLightContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(candlelightLight)
        }
    }

    @Nested
    inner class CandlelightDarkContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(candlelightDark)
        }
    }

    @Nested
    inner class ForestLightContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(forestLight)
        }
    }

    @Nested
    inner class ForestDarkContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(forestDark)
        }
    }

    @Nested
    inner class MoonLightContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(moonLight)
        }
    }

    @Nested
    inner class MoonDarkContrast {
        @Test
        fun `all combinations meet WCAG AA`() {
            assertAllCombinations(moonDark)
        }
    }

    // endregion

    // region Luminance Formula Sanity Checks

    @Nested
    inner class LuminanceFormula {
        @Test
        fun `black has zero luminance`() {
            val luminance = relativeLuminance(Color.Black)
            assertTrue(luminance < 0.001) { "Black luminance should be ~0, was $luminance" }
        }

        @Test
        fun `white has full luminance`() {
            val luminance = relativeLuminance(Color.White)
            assertTrue(luminance > 0.999) { "White luminance should be ~1, was $luminance" }
        }

        @Test
        fun `black on white has maximum contrast`() {
            val ratio = contrastRatio(Color.Black, Color.White)
            assertTrue(ratio > 20.9 && ratio < 21.1) { "Black/white contrast should be ~21:1, was $ratio" }
        }
    }

    // endregion
}
