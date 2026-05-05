package com.stillmoment.data.local

import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.Praxis
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for PraxisDataStore migration and serialization logic.
 * Note: Actual DataStore integration tests require instrumented tests (Android context).
 * These tests verify the pure logic: migration from MeditationSettings, JSON serialization,
 * and migration detection conditions.
 */
class PraxisDataStoreTest {
    // MARK: - Migration Detection

    @Nested
    inner class MigrationDetection {
        @Test
        fun `default MeditationSettings equals Default constant`() {
            val settings = MeditationSettings()
            assertEquals(MeditationSettings.Default, settings)
        }

        @Test
        fun `non-default MeditationSettings differs from Default`() {
            val settings = MeditationSettings(durationMinutes = 20)
            assertFalse(settings == MeditationSettings.Default)
        }

        @Test
        fun `settings with changed backgroundSoundId differs from Default`() {
            val settings = MeditationSettings(backgroundSoundId = "forest")
            assertFalse(settings == MeditationSettings.Default)
        }

        @Test
        fun `settings with changed gongSoundId differs from Default`() {
            val settings = MeditationSettings(gongSoundId = "clear-strike")
            assertFalse(settings == MeditationSettings.Default)
        }

        @Test
        fun `settings with changed intervalGongsEnabled differs from Default`() {
            val settings = MeditationSettings(intervalGongsEnabled = true)
            assertFalse(settings == MeditationSettings.Default)
        }
    }

    // MARK: - Migration from MeditationSettings

    @Nested
    inner class MigrationFromSettings {
        @Test
        fun `fromMeditationSettings preserves custom duration`() {
            val settings = MeditationSettings(durationMinutes = 25)
            val praxis = Praxis.fromMeditationSettings(settings)
            assertEquals(25, praxis.durationMinutes)
        }

        @Test
        fun `fromMeditationSettings preserves custom background sound`() {
            val settings = MeditationSettings(backgroundSoundId = "forest")
            val praxis = Praxis.fromMeditationSettings(settings)
            assertEquals("forest", praxis.backgroundSoundId)
        }

        @Test
        fun `fromMeditationSettings preserves custom gong sound`() {
            val settings = MeditationSettings(gongSoundId = "clear-strike")
            val praxis = Praxis.fromMeditationSettings(settings)
            assertEquals("clear-strike", praxis.gongSoundId)
        }

        @Test
        fun `fromMeditationSettings preserves interval settings`() {
            val settings = MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                intervalMode = IntervalMode.BEFORE_END,
                intervalSoundId = "soft-interval",
                intervalGongVolume = 0.6f
            )
            val praxis = Praxis.fromMeditationSettings(settings)

            assertTrue(praxis.intervalGongsEnabled)
            assertEquals(10, praxis.intervalMinutes)
            assertEquals(IntervalMode.BEFORE_END, praxis.intervalMode)
            assertEquals("soft-interval", praxis.intervalSoundId)
            assertEquals(0.6f, praxis.intervalGongVolume)
        }

        @Test
        fun `fromMeditationSettings preserves preparation time settings`() {
            val settings = MeditationSettings(
                preparationTimeEnabled = false,
                preparationTimeSeconds = 30
            )
            val praxis = Praxis.fromMeditationSettings(settings)

            assertFalse(praxis.preparationTimeEnabled)
            assertEquals(30, praxis.preparationTimeSeconds)
        }

        @Test
        fun `fromMeditationSettings preserves volume settings`() {
            val settings = MeditationSettings(
                gongVolume = 0.8f,
                backgroundSoundVolume = 0.3f
            )
            val praxis = Praxis.fromMeditationSettings(settings)

            assertEquals(0.8f, praxis.gongVolume)
            assertEquals(0.3f, praxis.backgroundSoundVolume)
        }

        @Test
        fun `fromMeditationSettings with all custom values`() {
            val settings = MeditationSettings.create(
                intervalGongsEnabled = true,
                intervalMinutes = 15,
                intervalMode = IntervalMode.AFTER_START,
                intervalSoundId = "temple-bell",
                intervalGongVolume = 0.9f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.4f,
                durationMinutes = 45,
                preparationTimeEnabled = false,
                preparationTimeSeconds = 20,
                gongSoundId = "deep-resonance",
                gongVolume = 0.7f,
            )

            val praxis = Praxis.fromMeditationSettings(settings)

            assertTrue(praxis.intervalGongsEnabled)
            assertEquals(15, praxis.intervalMinutes)
            assertEquals(IntervalMode.AFTER_START, praxis.intervalMode)
            assertEquals("temple-bell", praxis.intervalSoundId)
            assertEquals(0.9f, praxis.intervalGongVolume)
            assertEquals("forest", praxis.backgroundSoundId)
            assertEquals(0.4f, praxis.backgroundSoundVolume)
            assertEquals(45, praxis.durationMinutes)
            assertFalse(praxis.preparationTimeEnabled)
            assertEquals(20, praxis.preparationTimeSeconds)
            assertEquals("deep-resonance", praxis.gongSoundId)
            assertEquals(0.7f, praxis.gongVolume)
        }
    }

    // MARK: - JSON Serialization

    @Nested
    inner class JsonSerialization {
        @Test
        fun `praxis survives JSON round-trip`() {
            val original = Praxis.create(
                id = "test-roundtrip-id",
                durationMinutes = 30,
                preparationTimeEnabled = true,
                preparationTimeSeconds = 20,
                gongSoundId = "clear-strike",
                gongVolume = 0.8f,
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                intervalMode = IntervalMode.BEFORE_END,
                intervalSoundId = "soft-interval",
                intervalGongVolume = 0.6f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.4f
            )

            val json = Json.encodeToString(original)
            val decoded = Json.decodeFromString<Praxis>(json)

            assertEquals(original, decoded)
        }

        @Test
        fun `default praxis survives JSON round-trip`() {
            val original = Praxis.create(id = "default-test-id")

            val json = Json.encodeToString(original)
            val decoded = Json.decodeFromString<Praxis>(json)

            assertEquals(original, decoded)
        }

        @Test
        fun `JSON contains expected key names`() {
            val praxis = Praxis.create(
                id = "json-fields-test",
                durationMinutes = 15
            )

            val json = Json.encodeToString(praxis)

            // Verify ID and key structural fields are present in serialized JSON
            assertTrue(json.contains("json-fields-test"), "JSON should contain the ID value")
            assertTrue(json.contains("durationMinutes"), "JSON should contain durationMinutes key: $json")
        }
    }

    // MARK: - Legacy JSON Compatibility

    @Nested
    inner class LegacyJsonCompatibility {
        private val lenientJson = Json { ignoreUnknownKeys = true }

        @Test
        fun `legacy praxis JSON with introductionId field decodes without throwing`() {
            // Mirrors the JSON written by app versions that still had the Einstimmung feature.
            // After shared-088 the Praxis class no longer has the Einstimmung fields, so the
            // decoder must ignore them (otherwise PraxisDataStore.load() returns null and the
            // user sees a fresh-install Praxis on upgrade).
            val legacyJson = """
                {
                  "id":"legacy-id",
                  "durationMinutes":12,
                  "preparationTimeEnabled":true,
                  "preparationTimeSeconds":15,
                  "gongSoundId":"classic-bowl",
                  "gongVolume":1.0,
                  "introductionId":"breath",
                  "introductionEnabled":true,
                  "intervalGongsEnabled":false,
                  "intervalMinutes":5,
                  "intervalMode":"REPEATING",
                  "intervalSoundId":"soft-interval",
                  "intervalGongVolume":0.75,
                  "backgroundSoundId":"silent",
                  "backgroundSoundVolume":0.15
                }
            """.trimIndent()

            val decoded = lenientJson.decodeFromString<Praxis>(legacyJson)

            assertEquals("legacy-id", decoded.id)
            assertEquals(12, decoded.durationMinutes)
        }

        @Test
        fun `re-encoded praxis no longer contains introduction keys`() {
            // After lenient decode, the Praxis object has no attunement state at all. Re-encoding
            // it must drop the legacy keys cleanly so the persisted JSON converges to the new
            // schema on the next save.
            val legacyJson = """
                {
                  "id":"legacy-id",
                  "durationMinutes":12,
                  "introductionId":"breath",
                  "introductionEnabled":true,
                  "preparationTimeEnabled":true,
                  "preparationTimeSeconds":15,
                  "gongSoundId":"classic-bowl",
                  "gongVolume":1.0,
                  "intervalGongsEnabled":false,
                  "intervalMinutes":5,
                  "intervalMode":"REPEATING",
                  "intervalSoundId":"soft-interval",
                  "intervalGongVolume":0.75,
                  "backgroundSoundId":"silent",
                  "backgroundSoundVolume":0.15
                }
            """.trimIndent()

            val decoded = lenientJson.decodeFromString<Praxis>(legacyJson)
            val reEncoded = Json.encodeToString(decoded)

            assertFalse(
                reEncoded.contains("introductionId"),
                "Re-encoded praxis still contains legacy introductionId key"
            )
            assertFalse(
                reEncoded.contains("introductionEnabled"),
                "Re-encoded praxis still contains legacy introductionEnabled key"
            )
        }
    }

    // MARK: - Fresh Install Defaults

    @Nested
    inner class FreshInstallDefaults {
        @Test
        fun `Default praxis has correct duration`() {
            assertEquals(
                Praxis.DEFAULT_DURATION_MINUTES,
                Praxis.Default.durationMinutes
            )
        }

        @Test
        fun `Default praxis has preparation enabled`() {
            assertTrue(Praxis.Default.preparationTimeEnabled)
        }

        @Test
        fun `Default praxis has correct preparation time`() {
            assertEquals(
                Praxis.DEFAULT_PREPARATION_TIME_SECONDS,
                Praxis.Default.preparationTimeSeconds
            )
        }

        @Test
        fun `Default praxis has correct gong sound`() {
            assertEquals(
                GongSound.DEFAULT_SOUND_ID,
                Praxis.Default.gongSoundId
            )
        }

        @Test
        fun `Default praxis has silent background`() {
            assertEquals("silent", Praxis.Default.backgroundSoundId)
        }

        @Test
        fun `Default praxis has interval gongs disabled`() {
            assertFalse(Praxis.Default.intervalGongsEnabled)
        }
    }
}
