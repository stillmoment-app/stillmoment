package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.graphics.Color
import com.stillmoment.domain.models.ColorTheme
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class ThemeResolutionTest {

    @Test
    fun `all light schemes are distinct`() {
        val lightSchemes = ColorTheme.entries.map { theme ->
            resolveColorScheme(theme, darkTheme = false)
        }
        assertEquals(3, lightSchemes.toSet().size)
    }

    @Test
    fun `all dark schemes are distinct`() {
        val darkSchemes = ColorTheme.entries.map { theme ->
            resolveColorScheme(theme, darkTheme = true)
        }
        assertEquals(3, darkSchemes.toSet().size)
    }

    @Test
    fun `candlelight light uses CdLight colors`() {
        val scheme = resolveColorScheme(ColorTheme.CANDLELIGHT, darkTheme = false)
        assertEquals(CdLightInteractive, scheme.primary)
        assertEquals(CdLightTextPrimary, scheme.onBackground)
        assertEquals(CdLightBgSecondary, scheme.background)
    }

    @Test
    fun `candlelight dark uses CdDark colors`() {
        val scheme = resolveColorScheme(ColorTheme.CANDLELIGHT, darkTheme = true)
        assertEquals(CdDarkInteractive, scheme.primary)
        assertEquals(CdDarkTextPrimary, scheme.onBackground)
        assertEquals(CdDarkBgSecondary, scheme.background)
    }

    @Test
    fun `forest light uses FoLight colors`() {
        val scheme = resolveColorScheme(ColorTheme.FOREST, darkTheme = false)
        assertEquals(FoLightInteractive, scheme.primary)
        assertEquals(FoLightTextPrimary, scheme.onBackground)
        assertEquals(FoLightBgSecondary, scheme.background)
    }

    @Test
    fun `forest dark uses FoDark colors`() {
        val scheme = resolveColorScheme(ColorTheme.FOREST, darkTheme = true)
        assertEquals(FoDarkInteractive, scheme.primary)
        assertEquals(FoDarkTextPrimary, scheme.onBackground)
        assertEquals(FoDarkBgSecondary, scheme.background)
    }

    @Test
    fun `moon light uses MnLight colors`() {
        val scheme = resolveColorScheme(ColorTheme.MOON, darkTheme = false)
        assertEquals(MnLightInteractive, scheme.primary)
        assertEquals(MnLightTextPrimary, scheme.onBackground)
        assertEquals(MnLightBgSecondary, scheme.background)
    }

    @Test
    fun `moon dark uses MnDark colors`() {
        val scheme = resolveColorScheme(ColorTheme.MOON, darkTheme = true)
        assertEquals(MnDarkInteractive, scheme.primary)
        assertEquals(MnDarkTextPrimary, scheme.onBackground)
        assertEquals(MnDarkBgSecondary, scheme.background)
    }

    @Test
    fun `light and dark variants of same theme differ`() {
        ColorTheme.entries.forEach { theme ->
            val light = resolveColorScheme(theme, darkTheme = false)
            val dark = resolveColorScheme(theme, darkTheme = true)
            assertNotEquals(light.primary, dark.primary, "Primary should differ for $theme")
            assertNotEquals(light.background, dark.background, "Background should differ for $theme")
        }
    }

    // region StillMomentColors

    @Nested
    inner class StillMomentColorsResolution {
        @Test
        fun `all themes resolve StillMomentColors for light`() {
            ColorTheme.entries.forEach { theme ->
                val colors = resolveStillMomentColors(theme, darkTheme = false)
                assertNotNull(colors.progress, "progress should be set for $theme light")
                assertNotNull(colors.controlTrack, "controlTrack should be set for $theme light")
                assertNotNull(colors.cardBackground, "cardBackground should be set for $theme light")
            }
        }

        @Test
        fun `all themes resolve StillMomentColors for dark`() {
            ColorTheme.entries.forEach { theme ->
                val colors = resolveStillMomentColors(theme, darkTheme = true)
                assertNotNull(colors.progress, "progress should be set for $theme dark")
                assertNotNull(colors.controlTrack, "controlTrack should be set for $theme dark")
                assertNotNull(colors.cardBackground, "cardBackground should be set for $theme dark")
            }
        }

        @Test
        fun `light themes have transparent cardBorder`() {
            ColorTheme.entries.forEach { theme ->
                val colors = resolveStillMomentColors(theme, darkTheme = false)
                assertEquals(Color.Transparent, colors.cardBorder, "Light $theme should have transparent cardBorder")
            }
        }

        @Test
        fun `dark themes have visible cardBorder`() {
            ColorTheme.entries.forEach { theme ->
                val colors = resolveStillMomentColors(theme, darkTheme = true)
                assertNotEquals(
                    Color.Transparent,
                    colors.cardBorder,
                    "Dark $theme should have a visible cardBorder"
                )
            }
        }

        @Test
        fun `light and dark StillMomentColors differ for each theme`() {
            ColorTheme.entries.forEach { theme ->
                val light = resolveStillMomentColors(theme, darkTheme = false)
                val dark = resolveStillMomentColors(theme, darkTheme = true)
                assertNotEquals(
                    light.controlTrack,
                    dark.controlTrack,
                    "controlTrack should differ for $theme"
                )
            }
        }

        @Test
        fun `all themes produce distinct colors`() {
            val lightColors = ColorTheme.entries.map { resolveStillMomentColors(it, darkTheme = false) }
            assertEquals(3, lightColors.toSet().size, "All light StillMomentColors should be distinct")

            val darkColors = ColorTheme.entries.map { resolveStillMomentColors(it, darkTheme = true) }
            assertEquals(3, darkColors.toSet().size, "All dark StillMomentColors should be distinct")
        }

        @Test
        fun `settingsValueAccent equals primary interactive for each theme`() {
            // shared-089: the value-text accent in the flat settings list must follow
            // colorScheme.primary so it inherits WCAG contrast guarantees and reacts
            // to theme + light/dark switches automatically.
            assertEquals(
                CdLightInteractive,
                resolveStillMomentColors(ColorTheme.CANDLELIGHT, darkTheme = false).settingsValueAccent
            )
            assertEquals(
                CdDarkInteractive,
                resolveStillMomentColors(ColorTheme.CANDLELIGHT, darkTheme = true).settingsValueAccent
            )
            assertEquals(
                FoLightInteractive,
                resolveStillMomentColors(ColorTheme.FOREST, darkTheme = false).settingsValueAccent
            )
            assertEquals(
                MnDarkInteractive,
                resolveStillMomentColors(ColorTheme.MOON, darkTheme = true).settingsValueAccent
            )
        }

        @Test
        fun `settingsDivider derives from controlTrack with reduced alpha`() {
            ColorTheme.entries.forEach { theme ->
                listOf(false, true).forEach { dark ->
                    val colors = resolveStillMomentColors(theme, darkTheme = dark)
                    assertEquals(
                        colors.controlTrack.copy(alpha = 0.30f),
                        colors.settingsDivider,
                        "settingsDivider should be controlTrack at alpha 0.30 for $theme dark=$dark"
                    )
                }
            }
        }

        @Test
        fun `dial active arc matches primary interactive`() {
            ColorTheme.entries.forEach { theme ->
                listOf(false, true).forEach { dark ->
                    val colors = resolveStillMomentColors(theme, darkTheme = dark)
                    assertEquals(
                        colors.settingsValueAccent,
                        colors.dialActiveArc,
                        "dialActiveArc should match settingsValueAccent for $theme dark=$dark"
                    )
                    assertEquals(
                        colors.settingsValueAccent,
                        colors.dialDropletCore,
                        "dialDropletCore should match settingsValueAccent for $theme dark=$dark"
                    )
                }
            }
        }
    }

    // endregion
}
