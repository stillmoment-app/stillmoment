package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class AppearanceModeTest {

    @Test
    fun `default is DARK`() {
        // shared-122: a fresh install presents the app dark, no matter how the device is set
        assertEquals(AppearanceMode.DARK, AppearanceMode.DEFAULT)
    }

    @Test
    fun `default resolves to dark independently of the device setting`() {
        // isDark = true forces dark; it does not defer to the system like SYSTEM (null) would
        assertEquals(true, AppearanceMode.DEFAULT.isDark)
    }

    @Test
    fun `stored SYSTEM selection wins over the dark default`() {
        // A user who explicitly picked "System" keeps it across app restarts -
        // the default must never overwrite a stored choice
        assertEquals(AppearanceMode.SYSTEM, AppearanceMode.fromString("SYSTEM"))
        assertEquals(null, AppearanceMode.fromString("SYSTEM").isDark)
    }

    @Test
    fun `stored LIGHT selection wins over the dark default`() {
        assertEquals(AppearanceMode.LIGHT, AppearanceMode.fromString("LIGHT"))
        assertEquals(false, AppearanceMode.fromString("LIGHT").isDark)
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
