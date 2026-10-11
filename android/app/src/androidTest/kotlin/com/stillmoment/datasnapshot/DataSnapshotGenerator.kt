package com.stillmoment.datasnapshot

import androidx.test.platform.app.InstrumentationRegistry
import com.stillmoment.data.local.CustomAudioDataStore
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.data.migration.AttunementCleanupMigration
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import com.stillmoment.domain.repositories.PraxisRepository
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import java.io.File
import javax.inject.Inject
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test

/**
 * Writes the canonical upgrade-test data ([CanonicalDataSnapshot]) through the app's real
 * storage classes (shared-144).
 *
 * Not a regular test: it wipes the app's DataStore files. Connected test runs
 * (`make test-ui`, CI) exclude it via `notClass` in `app/build.gradle.kts`; as a second
 * guard it only writes when the instrumentation argument `dataSnapshot=true` is set.
 * `scripts/capture-data-snapshot.sh` runs it and then copies the raw files from
 * `files/datastore/` into `src/test/resources/data-snapshots/<version>/`, where
 * [DataSnapshotUpgradeTest] reads them with every later version.
 *
 * Keep it to the injected classes and calls older releases already had, so it can be
 * copied into a release tag to regenerate that release's snapshot.
 */
@HiltAndroidTest
class DataSnapshotGenerator {
    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var attunementCleanupMigration: AttunementCleanupMigration

    @Inject
    lateinit var meditationDataStore: GuidedMeditationDataStore

    @Inject
    lateinit var meditationRepository: GuidedMeditationRepository

    @Inject
    lateinit var praxisRepository: PraxisRepository

    @Inject
    lateinit var customAudioDataStore: CustomAudioDataStore

    @Inject
    lateinit var settingsDataStore: SettingsDataStore

    @Inject
    lateinit var guidedMeditationSettingsRepository: GuidedMeditationSettingsRepository

    @Test
    fun writeCanonicalDataSnapshot() {
        assumeTrue(
            "Data snapshot generator runs only with -e $ARGUMENT true",
            InstrumentationRegistry.getArguments().getString(ARGUMENT) == "true"
        )

        // Fresh install state: nothing has opened a DataStore in this process yet.
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        File(context.filesDir, "datastore").deleteRecursively()
        hiltRule.inject()

        runBlocking {
            // App start (StillMomentApp.onCreate), then the library's first read with its
            // one-shot migration — both leave their markers in the files like on a device.
            attunementCleanupMigration.runIfNeeded()
            meditationRepository.meditationsFlow.first()
            praxisRepository.load()

            // What the user sets up. Imports store exactly these entries; the audio files
            // themselves are not part of the snapshot.
            meditationDataStore.addMeditation(CanonicalDataSnapshot.meditation)
            customAudioDataStore.addFile(CanonicalDataSnapshot.ownSound)
            praxisRepository.save(CanonicalDataSnapshot.praxis)
            settingsDataStore.setAppearanceMode(CanonicalDataSnapshot.appearanceMode)
            guidedMeditationSettingsRepository.updateSettings(CanonicalDataSnapshot.guidedMeditationSettings)
        }
    }

    private companion object {
        const val ARGUMENT = "dataSnapshot"
    }
}
