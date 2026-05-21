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
        fun `light has transparent cardBorder`() {
            val colors = resolveStillMomentColors(darkTheme = false)
            assertEquals(Color.Transparent, colors.cardBorder, "Light should have transparent cardBorder")
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
        fun `settingsDivider derives from controlTrack with reduced alpha`() {
            listOf(false, true).forEach { dark ->
                val colors = resolveStillMomentColors(darkTheme = dark)
                assertEquals(
                    colors.controlTrack.copy(alpha = 0.30f),
                    colors.settingsDivider,
                    "settingsDivider should be controlTrack at alpha 0.30 for dark=$dark"
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

    // endregion
}
