package com.stillmoment.infrastructure.audio

import android.content.Context
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.WaveformCacheServiceProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.IOException
import javax.inject.Inject
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Concrete [WaveformCacheServiceProtocol] (shared-107).
 *
 * Stores one JSON file per meditation under `filesDir/waveforms/{id}.json` (analogous to
 * iOS' `Application Support/Waveforms/`). The directory is injectable so tests can use a
 * temporary directory. Entries are small and never invalidated (non-destructive audio).
 */
class WaveformCacheService(
    private val directory: File,
    private val logger: LoggerProtocol
) : WaveformCacheServiceProtocol {
    @Inject
    constructor(
        @ApplicationContext context: Context,
        logger: LoggerProtocol
    ) : this(File(context.filesDir, WAVEFORMS_DIR), logger)

    override fun load(id: String): MeditationWaveform? {
        val file = fileFor(id)
        if (!file.exists()) {
            return null
        }
        return try {
            Json.decodeFromString<MeditationWaveform>(file.readText())
        } catch (e: SerializationException) {
            logger.e(TAG, "Failed to decode cached waveform for $id", e)
            null
        } catch (e: IOException) {
            logger.e(TAG, "Failed to read cached waveform for $id", e)
            null
        }
    }

    override fun save(id: String, waveform: MeditationWaveform) {
        if (!directory.exists()) {
            directory.mkdirs()
        }
        fileFor(id).writeText(Json.encodeToString(waveform))
    }

    override fun delete(id: String) {
        val file = fileFor(id)
        if (!file.exists()) {
            return
        }
        if (!file.delete()) {
            logger.w(TAG, "Failed to delete cached waveform for $id")
        }
    }

    private fun fileFor(id: String): File = File(directory, "$id.json")

    private companion object {
        const val WAVEFORMS_DIR = "waveforms"
        const val TAG = "WaveformCache"
    }
}
