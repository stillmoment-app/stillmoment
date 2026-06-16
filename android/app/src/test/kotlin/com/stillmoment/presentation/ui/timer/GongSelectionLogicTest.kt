package com.stillmoment.presentation.ui.timer

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for the pure gong-picker layout decisions (shared-115/shared-106).
 */
class GongSelectionLogicTest {
    @Nested
    inner class VolumeCardVisibility {
        @Test
        fun `volume card shows for audible gongs`() {
            assertTrue(GongSelectionLogic.isVolumeCardVisible("temple-bell"))
        }

        @Test
        fun `volume card hidden for vibration`() {
            assertFalse(GongSelectionLogic.isVolumeCardVisible("vibration"))
        }
    }

    @Nested
    inner class SoundListVisibility {
        @Test
        fun `sound list hidden when both gongs are off`() {
            assertFalse(GongSelectionLogic.isSoundListVisible(startGongEnabled = false, endGongEnabled = false))
        }

        @Test
        fun `sound list shows when the start gong is on`() {
            assertTrue(GongSelectionLogic.isSoundListVisible(startGongEnabled = true, endGongEnabled = false))
        }

        @Test
        fun `sound list shows when the end gong is on`() {
            assertTrue(GongSelectionLogic.isSoundListVisible(startGongEnabled = false, endGongEnabled = true))
        }

        @Test
        fun `sound list shows when both gongs are on`() {
            assertTrue(GongSelectionLogic.isSoundListVisible(startGongEnabled = true, endGongEnabled = true))
        }
    }
}
