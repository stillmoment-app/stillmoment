package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class AppearanceModeTest {

    @Test
    fun `default is SYSTEM`() {
        assertEquals(AppearanceMode.SYSTEM, AppearanceMode.DEFAULT)
    }

    @Test
    fun `entries contains all three modes in picker order`() {
        assertEquals(3, AppearanceMode.entries.size)
        assertEquals(AppearanceMode.SYSTEM, AppearanceMode.entries[0])
        assertEquals(AppearanceMode.LIGHT, AppearanceMode.entries[1])
        assertEquals(AppearanceMode.DARK, AppearanceMode.entries[2])
    }

    @Test
    fun `name values are stable for persistence`() {
        assertEquals("SYSTEM", AppearanceMode.SYSTEM.name)
        assertEquals("LIGHT", AppearanceMode.LIGHT.name)
        assertEquals("DARK", AppearanceMode.DARK.name)
    }

    @Test
    fun `fromString roundtrip for all entries`() {
        AppearanceMode.entries.forEach { mode ->
            assertEquals(mode, AppearanceMode.fromString(mode.name))
        }
    }

    @Test
    fun `fromString returns DEFAULT for null`() {
        assertEquals(AppearanceMode.DEFAULT, AppearanceMode.fromString(null))
    }

    @Test
    fun `fromString returns DEFAULT for unknown value`() {
        assertEquals(AppearanceMode.DEFAULT, AppearanceMode.fromString("UNKNOWN_MODE"))
    }

    @Test
    fun `fromString returns DEFAULT for empty string`() {
        assertEquals(AppearanceMode.DEFAULT, AppearanceMode.fromString(""))
    }

    @Test
    fun `isDark returns correct values for each mode`() {
        assertEquals(null, AppearanceMode.SYSTEM.isDark)
        assertEquals(false, AppearanceMode.LIGHT.isDark)
        assertEquals(true, AppearanceMode.DARK.isDark)
    }
}
