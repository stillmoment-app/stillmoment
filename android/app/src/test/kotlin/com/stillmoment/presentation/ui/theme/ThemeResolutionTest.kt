package com.stillmoment.presentation.ui.theme

import com.stillmoment.domain.models.ColorTheme
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
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
}
