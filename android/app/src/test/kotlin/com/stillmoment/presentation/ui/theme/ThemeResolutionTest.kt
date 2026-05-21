package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.graphics.Color
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class ThemeResolutionTest {

    @Test
    fun `light uses Sm light colors`() {
        val scheme = resolveColorScheme(darkTheme = false)
        assertEquals(SmLightInteractive, scheme.primary)
        assertEquals(SmLightTextPrimary, scheme.onBackground)
        assertEquals(SmLightBgSecondary, scheme.background)
    }

    @Test
    fun `dark uses Sm dark colors`() {
        val scheme = resolveColorScheme(darkTheme = true)
        assertEquals(SmDarkInteractive, scheme.primary)
        assertEquals(SmDarkTextPrimary, scheme.onBackground)
        assertEquals(SmDarkBgSecondary, scheme.background)
    }

    @Test
    fun `light and dark variants differ`() {
        val light = resolveColorScheme(darkTheme = false)
        val dark = resolveColorScheme(darkTheme = true)
        assertNotEquals(light.primary, dark.primary, "Primary should differ between light and dark")
        assertNotEquals(light.background, dark.background, "Background should differ between light and dark")
    }

    // region StillMomentColors

    @Nested
    inner class StillMomentColorsResolution {
        @Test
        fun `light StillMomentColors resolves all roles`() {
            val colors = resolveStillMomentColors(darkTheme = false)
            assertNotNull(colors.progress, "progress should be set for light")
            assertNotNull(colors.controlTrack, "controlTrack should be set for light")
            assertNotNull(colors.cardBackground, "cardBackground should be set for light")
        }

        @Test
        fun `dark StillMomentColors resolves all roles`() {
            val colors = resolveStillMomentColors(darkTheme = true)
            assertNotNull(colors.progress, "progress should be set for dark")
            assertNotNull(colors.controlTrack, "controlTrack should be set for dark")
            assertNotNull(colors.cardBackground, "cardBackground should be set for dark")
        }

        @Test
        fun `light has visible warm cardBorder`() {
            val colors = resolveStillMomentColors(darkTheme = false)
            // shared-094: light cardBorder is no longer Transparent; it carries a warm
            // copper hint (alpha 0.11 in the 78371C accent family).
            assertNotEquals(
                Color.Transparent,
                colors.cardBorder,
                "Light should have a visible warm cardBorder after shared-094"
            )
        }

        @Test
        fun `dark has visible cardBorder`() {
            val colors = resolveStillMomentColors(darkTheme = true)
            assertNotEquals(
                Color.Transparent,
                colors.cardBorder,
                "Dark should have a visible cardBorder"
            )
        }

        @Test
        fun `light and dark StillMomentColors differ`() {
            val light = resolveStillMomentColors(darkTheme = false)
            val dark = resolveStillMomentColors(darkTheme = true)
            assertNotEquals(
                light.controlTrack,
                dark.controlTrack,
                "controlTrack should differ between light and dark"
            )
        }

        @Test
        fun `settingsValueAccent equals primary interactive`() {
            // shared-089: the value-text accent in the flat settings list must follow
            // colorScheme.primary so it inherits WCAG contrast guarantees and reacts
            // to light/dark switches automatically.
            assertEquals(
                SmLightInteractive,
                resolveStillMomentColors(darkTheme = false).settingsValueAccent
            )
            assertEquals(
                SmDarkInteractive,
                resolveStillMomentColors(darkTheme = true).settingsValueAccent
            )
        }

        @Test
        fun `settingsDivider equals divider in shared-094`() {
            // shared-094: settingsDivider and the new generic divider point at the
            // same warm-tinted value — the two slots intentionally share Hue/Alpha.
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                assertEquals(
                    colors.divider,
                    colors.settingsDivider,
                    "settingsDivider should equal divider after shared-094 (dark=$dark)"
                )
            }
        }

        @Test
        fun `dial active arc matches primary interactive`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                assertEquals(
                    colors.settingsValueAccent,
                    colors.dialActiveArc,
                    "dialActiveArc should match settingsValueAccent for dark=$dark"
                )
                assertEquals(
                    colors.settingsValueAccent,
                    colors.dialDropletCore,
                    "dialDropletCore should match settingsValueAccent for dark=$dark"
                )
            }
        }
    }

    // region shared-094 — Refinement tokens

    @Nested
    inner class Shared094Tokens {
        @Test
        fun `playGradient top and bot differ in light`() {
            val colors = resolveStillMomentColors(darkTheme = false)
            assertNotEquals(
                colors.playGradientTop,
                colors.playGradientBot,
                "Light playGradient should have two distinct stops"
            )
        }

        @Test
        fun `playGradient top and bot differ in dark`() {
            val colors = resolveStillMomentColors(darkTheme = true)
            assertNotEquals(
                colors.playGradientTop,
                colors.playGradientBot,
                "Dark playGradient should have two distinct stops"
            )
        }

        @Test
        fun `divider differs between light and dark`() {
            val light = resolveStillMomentColors(darkTheme = false)
            val dark = resolveStillMomentColors(darkTheme = true)
            assertNotEquals(
                light.divider,
                dark.divider,
                "divider should differ between light and dark (warm copper vs cream)"
            )
        }

        @Test
        fun `accentBannerBackground derives from interactive at alpha 0_10`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                val interactive = colors.settingsValueAccent
                assertEquals(
                    interactive.copy(alpha = 0.10f),
                    colors.accentBannerBackground,
                    "accentBannerBackground should be interactive @ alpha 0.10 (dark=$dark)"
                )
            }
        }

        @Test
        fun `accentBannerBorder derives from interactive at alpha 0_28`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                val interactive = colors.settingsValueAccent
                assertEquals(
                    interactive.copy(alpha = 0.28f),
                    colors.accentBannerBorder,
                    "accentBannerBorder should be interactive @ alpha 0.28 (dark=$dark)"
                )
            }
        }

        @Test
        fun `accentBubbleBackground derives from interactive at alpha 0_18`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                val interactive = colors.settingsValueAccent
                assertEquals(
                    interactive.copy(alpha = 0.18f),
                    colors.accentBubbleBackground,
                    "accentBubbleBackground should be interactive @ alpha 0.18 (dark=$dark)"
                )
            }
        }

        @Test
        fun `tabBarBackground equals cardBackground`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                assertEquals(
                    colors.cardBackground,
                    colors.tabBarBackground,
                    "tabBarBackground should equal cardBackground (dark=$dark)"
                )
            }
        }

        @Test
        fun `cardShadow is transparent in dark mode`() {
            val colors = resolveStillMomentColors(darkTheme = true)
            assertEquals(
                Color.Transparent,
                colors.cardShadow,
                "Dark mode uses border strategy — cardShadow must be transparent"
            )
        }

        @Test
        fun `cardShadow is non-transparent in light mode`() {
            val colors = resolveStillMomentColors(darkTheme = false)
            assertNotEquals(
                Color.Transparent,
                colors.cardShadow,
                "Light mode carries the lift via cardShadow — must be tinted"
            )
        }
    }

    // endregion

    // endregion
}
