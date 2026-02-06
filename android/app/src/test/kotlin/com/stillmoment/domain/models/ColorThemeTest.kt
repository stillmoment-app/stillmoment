package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ColorThemeTest {

    @Test
    fun `default is CANDLELIGHT`() {
        assertEquals(ColorTheme.CANDLELIGHT, ColorTheme.DEFAULT)
    }

    @Test
    fun `entries contains all three themes in picker order`() {
        assertEquals(3, ColorTheme.entries.size)
        assertEquals(ColorTheme.CANDLELIGHT, ColorTheme.entries[0])
        assertEquals(ColorTheme.FOREST, ColorTheme.entries[1])
        assertEquals(ColorTheme.MOON, ColorTheme.entries[2])
    }

    @Test
    fun `name values are stable for persistence`() {
        assertEquals("CANDLELIGHT", ColorTheme.CANDLELIGHT.name)
        assertEquals("FOREST", ColorTheme.FOREST.name)
        assertEquals("MOON", ColorTheme.MOON.name)
    }

    @Test
    fun `fromString roundtrip for all entries`() {
        ColorTheme.entries.forEach { theme ->
            assertEquals(theme, ColorTheme.fromString(theme.name))
        }
    }

    @Test
    fun `fromString returns DEFAULT for null`() {
        assertEquals(ColorTheme.DEFAULT, ColorTheme.fromString(null))
    }

    @Test
    fun `fromString returns DEFAULT for unknown value`() {
        assertEquals(ColorTheme.DEFAULT, ColorTheme.fromString("UNKNOWN_THEME"))
    }

    @Test
    fun `fromString returns DEFAULT for empty string`() {
        assertEquals(ColorTheme.DEFAULT, ColorTheme.fromString(""))
    }
}
