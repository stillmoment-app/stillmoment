package com.stillmoment.data.local

import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/**
 * A play length detected in the background (android-079) is written into the
 * stored list. The file may have been deleted or renamed in the meantime.
 */
class CustomAudioDurationUpdateTest {
    private val rain = soundscape(id = "rain", name = "Rain")
    private val wind = soundscape(id = "wind", name = "Wind")

    @Test
    fun `detected play length is stored for the imported file only`() {
        val updated = listOf(rain, wind).withDetectedDuration("rain", 1_800_000L)

        assertEquals(listOf(rain.copy(durationMs = 1_800_000L), wind), updated)
    }

    @Test
    fun `play length for a file deleted in the meantime is dropped`() {
        val updated = listOf(wind).withDetectedDuration("rain", 1_800_000L)

        assertEquals(listOf(wind), updated)
    }

    @Test
    fun `renaming during detection is kept`() {
        val renamed = rain.copy(name = "Evening Rain")

        val updated = listOf(renamed).withDetectedDuration("rain", 1_800_000L)

        assertEquals("Evening Rain", updated.single().name)
        assertEquals(1_800_000L, updated.single().durationMs)
    }

    private fun soundscape(id: String, name: String) = CustomAudioFile(
        id = id,
        name = name,
        filename = "$id.mp3",
        durationMs = null,
        type = CustomAudioType.SOUNDSCAPE,
        dateAdded = 1000L
    )
}
