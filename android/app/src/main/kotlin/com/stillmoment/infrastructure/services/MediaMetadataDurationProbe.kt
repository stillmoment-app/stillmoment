package com.stillmoment.infrastructure.services

import android.media.MediaMetadataRetriever
import com.stillmoment.domain.services.AudioDurationProbe
import com.stillmoment.domain.services.LoggerProtocol
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * [AudioDurationProbe] backed by `MediaMetadataRetriever`, reading the local copy of
 * an imported file. For MP3s without a VBR header the retriever scans the whole
 * file, which can take a long time on slow devices — hence the background use
 * (android-079).
 *
 * A file deleted while detection is pending yields null instead of an error.
 */
@Singleton
class MediaMetadataDurationProbe
@Inject
constructor(
    private val logger: LoggerProtocol
) : AudioDurationProbe {
    override suspend fun durationMs(filePath: String): Long? = withContext(Dispatchers.IO) {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(filePath)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
        } catch (e: IllegalArgumentException) {
            logger.w(TAG, "Cannot read play length of $filePath: ${e.message}")
            null
        } catch (e: IllegalStateException) {
            logger.w(TAG, "MediaMetadataRetriever in invalid state for $filePath: ${e.message}")
            null
        } catch (e: SecurityException) {
            logger.w(TAG, "Permission denied for $filePath: ${e.message}")
            null
        } finally {
            try {
                retriever.release()
            } catch (e: IOException) {
                logger.w(TAG, "Error releasing retriever: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "DurationProbe"
    }
}
