package com.stillmoment.datasnapshot

import com.stillmoment.domain.models.Praxis
import java.io.File
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Assertions.fail
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.TestFactory

/**
 * Upgrade test (shared-144): the current version must take over the data of every
 * released version completely.
 *
 * Each folder under `src/test/resources/data-snapshots/` holds the raw DataStore files a
 * release left on the device, written by that release's own code ([DataSnapshotGenerator],
 * run by `make release-prepare`). Snapshots accumulate — users skip updates, so every one
 * of them must stay readable. A failure names the version and the value that got lost.
 *
 * Not covered on purpose: Android never had a fallback for the formerly combined gong
 * switch of a guided meditation. All snapshots store both switches separately; this test
 * checks both and does not pretend such a fallback exists.
 */
class DataSnapshotUpgradeTest {
    @TestFactory
    fun `every stored release snapshot is read without losing a value`(): List<DynamicTest> {
        val versions = snapshotVersions()
        assertTrue(versions.isNotEmpty()) { "No data snapshots found under $SNAPSHOTS_RESOURCE" }
        return versions.map { (version, dir) ->
            DynamicTest.dynamicTest("Datenstand $version") { verifySnapshot(version, dir) }
        }
    }

    private fun verifySnapshot(version: String, dir: File) {
        val content = DataSnapshotReader(dir).use { it.read() }
        val failures = expectations(content).mapNotNull { (value, expected, actual) ->
            if (expected == actual) null else "$value: expected <$expected> but was <$actual>"
        }
        if (failures.isNotEmpty()) {
            // One line, so test summaries that show only the first line still name every value.
            fail<Unit>("Datenstand $version lost or changed: " + failures.joinToString("; "))
        }
    }

    private fun expectations(content: SnapshotContent): List<Triple<String, Any?, Any?>> =
        meditationExpectations(content) + praxisExpectations(content.praxis) + settingsExpectations(content)

    private fun meditationExpectations(content: SnapshotContent): List<Triple<String, Any?, Any?>> {
        val expectedMeditation = CanonicalDataSnapshot.meditation
        val meditation = content.meditations.find { it.id == expectedMeditation.id }
        return listOf(
            Triple("Meditation present", true, meditation != null),
            Triple("Meditation.teacher", expectedMeditation.teacher, meditation?.teacher),
            Triple("Meditation.name", expectedMeditation.name, meditation?.name),
            Triple("Meditation.fileUri", expectedMeditation.fileUri, meditation?.fileUri),
            Triple("Meditation.fileName", expectedMeditation.fileName, meditation?.fileName),
            Triple("Meditation.duration", expectedMeditation.duration, meditation?.duration),
            Triple("Meditation.trimStartMs", expectedMeditation.trimStartMs, meditation?.trimStartMs),
            Triple("Meditation.trimEndMs", expectedMeditation.trimEndMs, meditation?.trimEndMs),
            Triple("Meditation.startGongEnabled", expectedMeditation.startGongEnabled, meditation?.startGongEnabled),
            Triple("Meditation.endGongEnabled", expectedMeditation.endGongEnabled, meditation?.endGongEnabled),
            Triple("Meditation.gongSoundId", expectedMeditation.gongSoundId, meditation?.gongSoundId)
        )
    }

    private fun praxisExpectations(praxis: Praxis): List<Triple<String, Any?, Any?>> {
        val expectedPraxis = CanonicalDataSnapshot.praxis
        return listOf(
            Triple("Praxis.id", expectedPraxis.id, praxis.id),
            Triple("Praxis.durationMinutes", expectedPraxis.durationMinutes, praxis.durationMinutes),
            Triple(
                "Praxis.preparationTimeEnabled",
                expectedPraxis.preparationTimeEnabled,
                praxis.preparationTimeEnabled
            ),
            Triple(
                "Praxis.preparationTimeSeconds",
                expectedPraxis.preparationTimeSeconds,
                praxis.preparationTimeSeconds
            ),
            Triple("Praxis.gongSoundId", expectedPraxis.gongSoundId, praxis.gongSoundId),
            Triple("Praxis.gongVolume", expectedPraxis.gongVolume, praxis.gongVolume),
            Triple("Praxis.intervalGongsEnabled", expectedPraxis.intervalGongsEnabled, praxis.intervalGongsEnabled),
            Triple("Praxis.intervalMinutes", expectedPraxis.intervalMinutes, praxis.intervalMinutes),
            Triple("Praxis.intervalMode", expectedPraxis.intervalMode, praxis.intervalMode),
            Triple("Praxis.intervalSoundId", expectedPraxis.intervalSoundId, praxis.intervalSoundId),
            Triple("Praxis.intervalGongVolume", expectedPraxis.intervalGongVolume, praxis.intervalGongVolume),
            Triple("Praxis.backgroundSoundId", expectedPraxis.backgroundSoundId, praxis.backgroundSoundId),
            Triple(
                "Praxis.backgroundSoundVolume",
                expectedPraxis.backgroundSoundVolume,
                praxis.backgroundSoundVolume
            )
        )
    }

    private fun settingsExpectations(content: SnapshotContent): List<Triple<String, Any?, Any?>> {
        val expectedSound = CanonicalDataSnapshot.ownSound
        val sound = content.ownSounds.find { it.id == expectedSound.id }
        val expectedGuided = CanonicalDataSnapshot.guidedMeditationSettings
        return listOf(
            Triple("Own sound present", true, sound != null),
            Triple("Own sound.name", expectedSound.name, sound?.name),
            Triple("Own sound.filename", expectedSound.filename, sound?.filename),
            Triple("Own sound.durationMs", expectedSound.durationMs, sound?.durationMs),
            Triple("Appearance", CanonicalDataSnapshot.appearanceMode, content.appearanceMode),
            Triple(
                "Guided preparation time enabled",
                expectedGuided.preparationTimeEnabled,
                content.guidedMeditationSettings.preparationTimeEnabled
            ),
            Triple(
                "Guided preparation time seconds",
                expectedGuided.preparationTimeSeconds,
                content.guidedMeditationSettings.preparationTimeSeconds
            )
        )
    }

    private fun snapshotVersions(): List<Pair<String, File>> {
        val url = javaClass.classLoader?.getResource(SNAPSHOTS_RESOURCE) ?: return emptyList()
        val root = File(url.toURI())
        return root.listFiles { file -> file.isDirectory }
            .orEmpty()
            .sortedBy { it.name }
            .map { it.name to it }
    }

    companion object {
        private const val SNAPSHOTS_RESOURCE = "data-snapshots"
    }
}
