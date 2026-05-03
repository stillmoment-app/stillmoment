package com.stillmoment.infrastructure.network

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.UrlAudioValidator
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Downloads audio files from HTTP/HTTPS URLs using HttpURLConnection.
 *
 * Validates the server's Content-Type header and saves the audio to
 * a temporary file in the app cache directory.
 */
@Singleton
class UrlAudioDownloaderImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : UrlAudioDownloaderProtocol {

    // Secondary constructor for testing — allows injecting seams for HttpURLConnection and Uri
    internal constructor(
        context: Context,
        logger: LoggerProtocol,
        connectionFactory: (String) -> HttpURLConnection,
        uriFromFile: (File) -> Uri
    ) : this(context, logger) {
        this.connectionFactory = connectionFactory
        this.uriFromFile = uriFromFile
    }

    private var connectionFactory: (String) -> HttpURLConnection = { url ->
        URL(url).openConnection() as HttpURLConnection
    }
    private var uriFromFile: (File) -> Uri = { file -> Uri.fromFile(file) }

    companion object {
        private const val TAG = "UrlDownload"
        private const val TIMEOUT_MS = 60_000

        // "application/octet-stream" included as fallback: servers often don't set specific audio types
        private val SUPPORTED_CONTENT_TYPES = setOf(
            "audio/mpeg",
            "audio/mp4",
            "audio/x-m4a",
            "audio/m4a",
            "application/octet-stream"
        )
    }

    override suspend fun download(url: String): Result<Uri> = withContext(Dispatchers.IO) {
        val connection = connectionFactory(url)
        try {
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.requestMethod = "GET"
            connection.setRequestProperty("User-Agent", "StillMoment/1.0")

            val responseCode = connection.responseCode
            if (responseCode != HttpURLConnection.HTTP_OK) {
                logger.w(TAG, "Download failed with HTTP $responseCode for $url")
                return@withContext Result.failure(Exception("Download failed: HTTP $responseCode"))
            }

            val contentType = connection.contentType?.substringBefore(";")?.trim()?.lowercase()
            if (contentType != null && contentType !in SUPPORTED_CONTENT_TYPES) {
                logger.w(TAG, "Unsupported content type: $contentType for $url")
                return@withContext Result.failure(Exception("Unsupported content type: $contentType"))
            }

            val filename = UrlAudioValidator.extractFilename(url)
            // Use a per-download sub-directory so the file keeps its original name
            // (e.g. "Moment-mal-01Atem.mp3") while still avoiding collisions across
            // repeated downloads of the same URL.
            val downloadDir = File(context.cacheDir, "dl_${System.currentTimeMillis()}")
            downloadDir.mkdirs()
            val tempFile = File(downloadDir, filename)

            connection.inputStream.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            logger.d(TAG, "Downloaded ${tempFile.length()} bytes from $url to ${tempFile.name}")
            Result.success(uriFromFile(tempFile))
        } catch (e: java.io.IOException) {
            logger.e(TAG, "IO error downloading $url", e)
            Result.failure(e)
        } catch (e: SecurityException) {
            logger.e(TAG, "Security error downloading $url", e)
            Result.failure(e)
        } catch (e: IllegalArgumentException) {
            logger.e(TAG, "Invalid URL $url", e)
            Result.failure(e)
        } finally {
            connection.disconnect()
        }
    }
}
