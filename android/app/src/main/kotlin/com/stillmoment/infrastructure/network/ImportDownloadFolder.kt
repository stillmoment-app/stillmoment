package com.stillmoment.infrastructure.network

import android.content.Context
import com.stillmoment.domain.services.ImportDownloadsProtocol
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.IOException
import java.net.URI
import java.net.URISyntaxException
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Where the link and podcast import put downloaded audio (android-087):
 * `cacheDir/link_import/<random id>/<server filename>`.
 *
 * - **One directory per download.** The file keeps its original name (it becomes
 *   the library's file name) and two downloads started at the same moment never
 *   share a place — neither when writing nor when one of them is discarded.
 * - **Own sub-folder.** Discarding and the start clean-up only ever touch this
 *   folder (plus the `dl_*` directories versions before android-087 left in
 *   `cacheDir`). Files other apps hand over and the library's copies
 *   (`filesDir/meditations`) can never be hit.
 * - **Start clean-up keeps this run's downloads.** [removeLeftovers] runs once per
 *   process start in the background, so a share that cold-starts the app may
 *   already be downloading. Directories created by this process are remembered
 *   and skipped; creating and cleaning share one lock.
 *
 * `cacheDir` rather than `filesDir`: the files are temporary by nature and the
 * system may reclaim them under storage pressure.
 */
@Singleton
class ImportDownloadFolder internal constructor(
    cacheDir: () -> File,
    private val logger: LoggerProtocol
) : ImportDownloadsProtocol {

    @Inject
    constructor(
        @ApplicationContext context: Context,
        logger: LoggerProtocol
    ) : this(cacheDir = { context.cacheDir }, logger = logger)

    companion object {
        private const val TAG = "ImportDownloads"
        private const val FOLDER_NAME = "link_import"

        /** Per-download directories of versions before android-087: `cacheDir/dl_<millis>/`. */
        private const val LEGACY_PREFIX = "dl_"
    }

    private val cacheDir: File by lazy(cacheDir)
    private val root: File by lazy { File(this.cacheDir, FOLDER_NAME) }

    private val lock = Any()
    private val createdThisRun = mutableSetOf<String>()

    /** A new, empty directory for exactly one download. */
    fun createDownloadDirectory(): File = synchronized(lock) {
        val name = UUID.randomUUID().toString()
        createdThisRun += name
        File(root, name).also { it.mkdirs() }
    }

    override suspend fun discard(uri: String) = withContext(Dispatchers.IO) {
        val directory = downloadDirectoryOf(uri) ?: return@withContext
        synchronized(lock) {
            if (directory.deleteRecursively()) {
                logger.d(TAG, "Discarded download ${directory.name}")
            } else {
                logger.w(TAG, "Could not fully discard download ${directory.name}")
            }
        }
    }

    override suspend fun removeLeftovers() = withContext(Dispatchers.IO) {
        synchronized(lock) {
            val leftovers = root.listFiles().orEmpty().filter { it.name !in createdThisRun } +
                cacheDir.listFiles().orEmpty().filter { it.isDirectory && it.name.startsWith(LEGACY_PREFIX) }
            leftovers.forEach { it.deleteRecursively() }
            if (leftovers.isNotEmpty()) {
                logger.d(TAG, "Removed ${leftovers.size} leftover download(s)")
            }
        }
    }

    /**
     * The per-download directory holding the file behind [uri], or `null` when the
     * file is not one of our downloads (other scheme, other folder, path tricks).
     */
    private fun downloadDirectoryOf(uri: String): File? {
        // Only file: URIs can be our downloads — content:// from other apps never is.
        if (!uri.startsWith("file:")) {
            return null
        }
        return try {
            val directory = File(URI(uri)).canonicalFile.parentFile
            directory?.takeIf { it.parentFile == root.canonicalFile }
        } catch (e: URISyntaxException) {
            logger.e(TAG, "Not a download, kept: $uri", e)
            null
        } catch (e: IllegalArgumentException) {
            logger.e(TAG, "Not a download, kept: $uri", e)
            null
        } catch (e: IOException) {
            logger.e(TAG, "Could not resolve $uri, kept", e)
            null
        }
    }
}
