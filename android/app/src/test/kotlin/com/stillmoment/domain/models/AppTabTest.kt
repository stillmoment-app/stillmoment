package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for AppTab domain model.
 */
class AppTabTest {

    @Nested
    inner class Entries {
        @Test
        fun `has exactly three tabs`() {
            assertEquals(3, AppTab.entries.size)
        }

        @Test
        fun `contains TIMER, LIBRARY and SETTINGS`() {
            val tabs = AppTab.entries.toSet()
            assertEquals(setOf(AppTab.TIMER, AppTab.LIBRARY, AppTab.SETTINGS), tabs)
        }
    }

    @Nested
    inner class Routes {
        @Test
        fun `TIMER has route timerGraph`() {
            assertEquals("timerGraph", AppTab.TIMER.route)
        }

        @Test
        fun `LIBRARY has route library`() {
            assertEquals("library", AppTab.LIBRARY.route)
        }

        @Test
        fun `SETTINGS has route settings`() {
            assertEquals("settings", AppTab.SETTINGS.route)
        }

        @Test
        fun `routes are stable for persistence`() {
            // Route strings must never change - they are persisted in DataStore
            assertEquals("timerGraph", AppTab.TIMER.route)
            assertEquals("library", AppTab.LIBRARY.route)
            assertEquals("settings", AppTab.SETTINGS.route)
        }
    }

    @Nested
    inner class Default {
        @Test
        fun `DEFAULT is LIBRARY`() {
            assertEquals(AppTab.LIBRARY, AppTab.DEFAULT)
        }
    }

    @Nested
    inner class FromRoute {
        @Test
        fun `parses TIMER route`() {
            assertEquals(AppTab.TIMER, AppTab.fromRoute("timerGraph"))
        }

        @Test
        fun `parses LIBRARY route`() {
            assertEquals(AppTab.LIBRARY, AppTab.fromRoute("library"))
        }

        @Test
        fun `parses SETTINGS route`() {
            assertEquals(AppTab.SETTINGS, AppTab.fromRoute("settings"))
        }

        @Test
        fun `returns DEFAULT for unknown route`() {
            assertEquals(AppTab.DEFAULT, AppTab.fromRoute("unknown"))
        }

        @Test
        fun `returns DEFAULT for null route`() {
            assertEquals(AppTab.DEFAULT, AppTab.fromRoute(null))
        }
    }
}
