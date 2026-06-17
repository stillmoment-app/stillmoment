package com.stillmoment.presentation.ui.timer

import com.stillmoment.domain.models.IntervalMode
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/**
 * Verifies the pure mapping from [IntervalMode] to its mode-help variant
 * (shared-120). This is the fachlich test: it asserts which help text applies
 * per mode, not the localized output strings (those live in the plurals
 * resources and are validated by the localization check).
 */
class IntervalModeHelpTest {
    @Test
    fun `repeating mode maps to repeating help`() {
        assertEquals(IntervalModeHelp.REPEATING, IntervalMode.REPEATING.modeHelp())
    }

    @Test
    fun `after-start mode maps to after-start help`() {
        assertEquals(IntervalModeHelp.AFTER_START, IntervalMode.AFTER_START.modeHelp())
    }

    @Test
    fun `before-end mode maps to before-end help`() {
        assertEquals(IntervalModeHelp.BEFORE_END, IntervalMode.BEFORE_END.modeHelp())
    }

    @Test
    fun `every mode has a distinct help variant`() {
        val helps = IntervalMode.entries.map { it.modeHelp() }.toSet()
        assertEquals(IntervalMode.entries.size, helps.size)
    }
}
