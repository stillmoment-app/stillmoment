package com.stillmoment.infrastructure.network

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.models.UrlAudioValidator
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLDecoder
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Downloads audio files from HTTP/HTTPS URLs using HttpURLConnection.
 *
 * Validates the server's Content-Type header and saves the audio to
 * a temporary file in the app cache directory. The filename is taken
 * from the server's `Content-Disposition` header when available
 * (relevant for redirect-URLs without a clean path filename, e.g.
 * audiodharma.org/talks/.../download → S3 with Content-Disposition),
 * else from the URL path, else from a Content-Type-based fallback.
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

    // Single-download assumption: the URL import flow runs sequentially, so we never have
    // two parallel downloads. @Volatile gives us cross-thread visibility without the
    // overhead of AtomicReference. We disconnect the connection on cancel() so a blocked
    // input-stream read unblocks immediately; the cancelled flag lets us translate the
    // resulting IOException into CancellationException.
    @Volatile
    private var currentConnection: HttpURLConnection? = null

    @Volatile
    private var cancelled: Boolean = false

    companion object {
        private const val TAG = "UrlDownload"
        private const val TIMEOUT_MS = 60_000

        // "audio/mp3" is non-standard but widely sent by CDNs (e.g. audiodharma's S3 backend
        // at linodeobjects.com) instead of the official "audio/mpeg".
        // "application/octet-stream" included as fallback: servers often don't set specific audio types
        private val SUPPORTED_CONTENT_TYPES = setOf(
            "audio/mpeg",
            "audio/mp3",
            "audio/mp4",
            "audio/x-m4a",
            "audio/m4a",
            "application/octet-stream"
        )

        private val AUDIO_EXTENSIONS = setOf("mp3", "m4a")

        // RFC 6266: filename*=UTF-8''percent-encoded-name
        private val FILENAME_STAR_REGEX =
            Regex("""filename\*=([^']*)'[^']*'([^;]+)""", RegexOption.IGNORE_CASE)

        // RFC 6266: filename="..." or filename=... (unquoted, up to next ;)
        private val FILENAME_QUOTED_REGEX =
            Regex("""filename=(?:"([^"]+)"|([^;]+))""", RegexOption.IGNORE_CASE)
    }

    override suspend fun download(url: String): Result<Uri> = withContext(Dispatchers.IO) {
        cancelled = false
        var connection: HttpURLConnection? = null
        try {
            connection = connectionFactory(url).also { currentConnection = it }
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.requestMethod = "GET"
            connection.setRequestProperty("User-Agent", "StillMoment/1.0")

            val responseCode = connection.responseCode
            if (responseCode != HttpURLConnection.HTTP_OK) {
                logger.w(TAG, "Download failed with HTTP $responseCode for $url")
                return@withContext Result.failure(UrlAudioDownloadError.Http(responseCode))
            }

            val contentType = connection.contentType?.substringBefore(";")?.trim()?.lowercase()
            if (contentType != null && contentType !in SUPPORTED_CONTENT_TYPES) {
                logger.w(TAG, "Unsupported content type: $contentType for $url")
                return@withContext Result.failure(UrlAudioDownloadError.NotAudio)
            }

            val filename = resolveFilename(
                url = url,
                contentDisposition = connection.getHeaderField("Content-Disposition"),
                contentType = contentType
            )
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

            if (cancelled) {
                tempFile.delete()
                return@withContext Result.failure(CancellationException("Download cancelled"))
            }

            logger.d(TAG, "Downloaded ${tempFile.length()} bytes from $url to ${tempFile.name}")
            Result.success(uriFromFile(tempFile))
        } catch (e: IOException) {
            // When cancel() disconnects the underlying connection, the input stream
            // throws an IOException. Translate that to CancellationException so callers
            // can distinguish user cancellation from genuine network errors.
            if (cancelled) {
                logger.d(TAG, "Download cancelled for $url (IO interrupted)")
                Result.failure(CancellationException("Download cancelled"))
            } else {
                logger.e(TAG, "IO error downloading $url", e)
                Result.failure(UrlAudioDownloadError.Network(e))
            }
        } catch (e: SecurityException) {
            logger.e(TAG, "Security error downloading $url", e)
            Result.failure(UrlAudioDownloadError.Network(e))
        } catch (e: IllegalArgumentException) {
            logger.e(TAG, "Invalid URL $url", e)
            Result.failure(UrlAudioDownloadError.Network(e))
        } finally {
            connection?.disconnect()
            currentConnection = null
        }
    }

    override fun cancel() {
        // Disconnecting unblocks any in-flight inputStream.read() with an IOException,
        // which the catch-block translates into a CancellationException result.
        cancelled = true
        currentConnection?.disconnect()
    }

    /**
     * Resolves the filename for the downloaded file. Priority:
     *  1. `Content-Disposition: filename=...` if it has an audio extension
     *     (real server filename — what the user wants in their library)
     *  2. URL path filename if it has an audio extension
     *  3. Content-Type-based fallback (`audio.mp3` / `audio.m4a`)
     */
    private fun resolveFilename(url: String, contentDisposition: String?, contentType: String?): String {
        parseContentDispositionFilename(contentDisposition)
            ?.takeIf { hasAudioExtension(it) }
            ?.let { return it }

        val urlFilename = UrlAudioValidator.extractFilename(url)
        if (hasAudioExtension(urlFilename)) {
            return urlFilename
        }
        return fallbackFilename(contentType)
    }

    private fun hasAudioExtension(name: String): Boolean {
        return name.substringAfterLast(".", "").lowercase() in AUDIO_EXTENSIONS
    }

    /**
     * Default filename based on Content-Type. `audio/mp4` and `audio/x-m4a` → m4a;
     * everything else (audio/mpeg, application/octet-stream, missing) → mp3.
     */
    private fun fallbackFilename(contentType: String?): String {
        val lowered = contentType.orEmpty()
        return if (lowered.startsWith("audio/mp4") ||
            lowered.startsWith("audio/x-m4a") ||
            lowered.startsWith("audio/m4a")
        ) {
            "audio.m4a"
        } else {
            "audio.mp3"
        }
    }

    /**
     * Parses `Content-Disposition: attachment; filename="foo.mp3"` (RFC 6266).
     * Supports both `filename="..."` and `filename*=UTF-8''...`. Strips path
     * separators as a defence — the header comes from the server and must not
     * be allowed to write outside the download directory.
     */
    private fun parseContentDispositionFilename(header: String?): String? {
        if (header.isNullOrBlank()) return null

        extractFilenameStar(header)?.let { return sanitizeFilename(it) }
        extractFilenameQuoted(header)?.let { return sanitizeFilename(it) }
        return null
    }

    private fun extractFilenameStar(header: String): String? {
        val match = FILENAME_STAR_REGEX.find(header) ?: return null
        val charset = match.groupValues[1].ifBlank { "UTF-8" }
        val raw = match.groupValues[2].trim()
        return runCatching { URLDecoder.decode(raw, charset) }.getOrDefault(raw)
    }

    private fun extractFilenameQuoted(header: String): String? {
        val match = FILENAME_QUOTED_REGEX.find(header) ?: return null
        val quoted = match.groupValues[1]
        val unquoted = match.groupValues[2]
        return quoted.ifBlank { unquoted }.trim().takeIf { it.isNotEmpty() }
    }

    private fun sanitizeFilename(name: String): String {
        // Strip any leading path components — defence against directory traversal.
        return name.substringAfterLast('/').substringAfterLast('\\')
    }
}
