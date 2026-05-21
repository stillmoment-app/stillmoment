package com.stillmoment.infrastructure.services

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import com.stillmoment.domain.models.AudioMetadata
import com.stillmoment.domain.services.AudioMetadataService
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Production implementation of [AudioMetadataService] backed by
 * `MediaMetadataRetriever`. Reads duration plus the ID3 artist (`TPE1`) and
 * title (`TIT2`) tags.
 *
 * Any extraction error is logged and surfaces as
 * `AudioMetadata(duration = 0L, artist = null, title = null)` — the prefill
 * cascade in `ImportPrefill` falls back to filename-only suggestions in that
 * case.
 */
@Singleton
class AndroidAudioMetadataService
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : AudioMetadataService {
    override suspend fun extract(uri: String): AudioMetadata = withContext(Dispatchers.IO) {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, Uri.parse(uri))
            AudioMetadata(
                duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull() ?: 0L,
                artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
                    ?.takeIf { it.isNotBlank() },
                title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                    ?.takeIf { it.isNotBlank() }
            )
        } catch (e: IllegalArgumentException) {
            logger.w(TAG, "Invalid data source for $uri: ${e.message}")
            AudioMetadata(duration = 0L, artist = null, title = null)
        } catch (e: IllegalStateException) {
            logger.w(TAG, "MediaMetadataRetriever in invalid state for $uri: ${e.message}")
            AudioMetadata(duration = 0L, artist = null, title = null)
        } catch (e: SecurityException) {
            logger.w(TAG, "Permission denied for $uri: ${e.message}")
            AudioMetadata(duration = 0L, artist = null, title = null)
        } finally {
            try {
                retriever.release()
            } catch (e: IllegalStateException) {
                logger.w(TAG, "Error releasing retriever: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "AudioMetadataService"
    }
}
