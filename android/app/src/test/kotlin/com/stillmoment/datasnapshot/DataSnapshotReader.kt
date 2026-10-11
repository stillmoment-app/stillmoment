package com.stillmoment.datasnapshot

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import com.stillmoment.data.local.APP_SETTINGS_FILE_NAME
import com.stillmoment.data.local.CUSTOM_AUDIO_FILE_NAME
import com.stillmoment.data.local.CustomAudioDataStore
import com.stillmoment.data.local.GUIDED_MEDITATIONS_FILE_NAME
import com.stillmoment.data.local.GUIDED_MEDITATION_SETTINGS_FILE_NAME
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.GuidedMeditationSettingsDataStore
import com.stillmoment.data.local.PRAXIS_FILE_NAME
import com.stillmoment.data.local.PraxisDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.data.migration.AttunementCleanupMigration
import com.stillmoment.data.repositories.GuidedMeditationRepositoryImpl
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.services.AudioMetadataService
import com.stillmoment.domain.services.LoggerProtocol
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.mockito.kotlin.mock

/** What the current code reads from one stored release (shared-144). */
data class SnapshotContent(
    val meditations: List<GuidedMeditation>,
    val praxis: Praxis,
    val ownSounds: List<CustomAudioFile>,
    val appearanceMode: AppearanceMode,
    val guidedMeditationSettings: GuidedMeditationSettings
)

/**
 * Reads a stored data snapshot the way the current app reads its own files after an
 * update: the raw DataStore files are copied into a scratch `files/datastore` folder,
 * the startup migration runs, and every value comes out of the real DataStore classes
 * (the library through [GuidedMeditationRepositoryImpl], which also runs its one-shot
 * migration before the first read).
 *
 * Each instance opens its own DataStores on its own copy, so several versions can be
 * read one after another in the same test process.
 */
class DataSnapshotReader(private val snapshotDir: File) : AutoCloseable {
    private val filesDir: File = Files.createTempDirectory("data-snapshot").toFile()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val logger: LoggerProtocol = mock()

    private val settingsStore by lazy { open(APP_SETTINGS_FILE_NAME) }
    private val customAudioStore by lazy { open(CUSTOM_AUDIO_FILE_NAME) }

    fun read(): SnapshotContent = runBlocking {
        AttunementCleanupMigration(settingsStore, customAudioStore, filesDir, logger).runIfNeeded()

        val settings = SettingsDataStore(settingsStore)
        val library =
            GuidedMeditationRepositoryImpl(
                context = mock<Context>(),
                dataStore = GuidedMeditationDataStore(open(GUIDED_MEDITATIONS_FILE_NAME)),
                settingsDataStore = settings,
                audioMetadataService = mock<AudioMetadataService>()
            )

        SnapshotContent(
            meditations = library.meditationsFlow.first(),
            praxis = PraxisDataStore(open(PRAXIS_FILE_NAME), logger).load(),
            ownSounds = CustomAudioDataStore(customAudioStore).loadAll(CustomAudioType.SOUNDSCAPE),
            appearanceMode = settings.getAppearanceMode(),
            guidedMeditationSettings =
            GuidedMeditationSettingsDataStore(open(GUIDED_MEDITATION_SETTINGS_FILE_NAME)).getSettings()
        )
    }

    override fun close() {
        scope.cancel()
        filesDir.deleteRecursively()
    }

    /**
     * Opens a DataStore on a copy of `<name>.preferences_pb`. A file the release did not
     * write stays absent, exactly as on a device, and reads as empty.
     */
    private fun open(name: String): DataStore<Preferences> {
        val fileName = "$name.preferences_pb"
        val target = File(filesDir, "datastore/$fileName")
        target.parentFile?.mkdirs()
        val source = File(snapshotDir, fileName)
        if (source.exists()) {
            source.copyTo(target)
        }
        return PreferenceDataStoreFactory.create(scope = scope, produceFile = { target })
    }
}
