package com.stillmoment.presentation.ui.timer

import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.Praxis
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Pendant zu iOS `TimerViewModelPraxisTests` (testBackgroundCard_*-Cases) und
 * den Card-Label-Tests aus shared-089. Locale-frei — Label-Strings werden im
 * Composable resolved.
 */
class IdleSettingsRowStateTest {

    private val basePraxis = Praxis()

    @Nested
    inner class Preparation {

        @Test
        fun `dims when preparation is disabled`() {
            val praxis = basePraxis.copy(preparationTimeEnabled = false)
            assertTrue(IdleSettingsRowState.preparationIsOff(praxis))
        }

        @Test
        fun `is active when preparation is enabled`() {
            val praxis = basePraxis.copy(preparationTimeEnabled = true)
            assertFalse(IdleSettingsRowState.preparationIsOff(praxis))
        }
    }

    @Nested
    inner class Gong {

        @Test
        fun `gong row never dims`() {
            // Gong is always selected — the row stays in the active visual state.
            assertFalse(IdleSettingsRowState.gongIsOff(basePraxis))
        }
    }

    @Nested
    inner class Interval {

        @Test
        fun `dims when interval gongs are disabled`() {
            val praxis = basePraxis.copy(intervalGongsEnabled = false)
            assertTrue(IdleSettingsRowState.intervalIsOff(praxis))
        }

        @Test
        fun `is active when interval gongs are enabled`() {
            val praxis = basePraxis.copy(intervalGongsEnabled = true)
            assertFalse(IdleSettingsRowState.intervalIsOff(praxis))
        }
    }

    @Nested
    inner class Background {

        @Test
        fun `dims when silence is selected`() {
            val praxis = basePraxis.copy(backgroundSoundId = BackgroundSound.SILENT_ID)
            assertTrue(IdleSettingsRowState.backgroundIsOff(praxis))
        }

        @Test
        fun `is active when a soundscape is selected`() {
            val praxis = basePraxis.copy(backgroundSoundId = "forest")
            assertFalse(IdleSettingsRowState.backgroundIsOff(praxis))
        }
    }
}
