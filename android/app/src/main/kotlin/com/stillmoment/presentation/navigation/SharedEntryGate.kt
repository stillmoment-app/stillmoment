package com.stillmoment.presentation.navigation

import android.net.Uri
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.scopes.ActivityRetainedScoped
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Something shared with the app or opened with it ("Open with" counts like sharing). */
sealed interface SharedEntry {

    /** Whether [other] is this entry shared once more. */
    fun isSameAs(other: SharedEntry): Boolean

    /** A shared address: ordinary audio link or Apple Podcasts link. */
    data class Link(val url: String) : SharedEntry {
        override fun isSameAs(other: SharedEntry): Boolean = other is Link && other.url == url
    }

    /**
     * A shared audio file. Apps may hand the same file over under a new content
     * address each time, so name and size identify it — like the library's own
     * duplicate check. Without a known size only the address counts: two files
     * of unknown size and name are not taken for the same one.
     */
    data class File(val uri: Uri, val fileName: String, val sizeBytes: Long?) : SharedEntry {
        override fun isSameAs(other: SharedEntry): Boolean =
            other is File && (other.uri == uri || (sizeBytes != null && other.hasNameAndSize(fileName, sizeBytes)))

        private fun hasNameAndSize(name: String, size: Long): Boolean = fileName == name && sizeBytes == size
    }
}

/**
 * Decides when a shared entry starts (shared-138).
 *
 * Rule: what the app has begun — loading, edit sheet, message — it finishes.
 * An entry shared meanwhile waits and starts on its own once the running import
 * has ended. At most one entry waits; among the waiting ones the last shared
 * wins (shared-132). The running entry shared again changes nothing.
 *
 * Whoever runs an import reports its end via [importEnded] — every way out of an
 * import must do so, otherwise no shared entry starts any more.
 *
 * Activity-retained: outlives dark mode / font size changes like the ViewModels
 * that share it, but a fresh Activity starts with a free gate. Called on the main
 * thread only.
 */
@ActivityRetainedScoped
class SharedEntryGate
@Inject
constructor(private val logger: LoggerProtocol) {

    private val _toStart = MutableStateFlow<SharedEntry?>(null)

    /** The entry that is to start now; its starter calls [started] when taking it over. */
    val toStart: StateFlow<SharedEntry?> = _toStart.asStateFlow()

    private var isBusy = false

    /** The shared entry being imported; `null` for an import without sharing. */
    private var running: SharedEntry? = null

    private var waiting: SharedEntry? = null

    /** Something was shared with the app. */
    fun share(entry: SharedEntry) {
        when {
            running?.isSameAs(entry) == true -> logger.d(TAG, "Shared again while it runs, ignored")
            isBusy -> {
                logger.d(TAG, if (waiting == null) "Busy, entry waits" else "Busy, entry replaces the waiting one")
                waiting = entry
            }
            else -> {
                logger.d(TAG, "Free, entry starts")
                start(entry)
            }
        }
    }

    /** The starter took [toStart] over. */
    fun started() {
        _toStart.value = null
    }

    /** An import began without sharing (file picker, edit sheet of a meditation). */
    fun importBegan() {
        if (isBusy) {
            return
        }
        logger.d(TAG, "Import without sharing began, busy")
        isBusy = true
        running = null
    }

    /** The running import has ended — saved, discarded, message closed or cancelled. */
    fun importEnded() {
        if (!isBusy) {
            logger.w(TAG, "Import ended while nothing runs")
            return
        }
        val next = waiting
        waiting = null
        if (next == null) {
            logger.d(TAG, "Import ended, free")
            isBusy = false
            running = null
        } else {
            logger.d(TAG, "Import ended, waiting entry starts")
            start(next)
        }
    }

    private fun start(entry: SharedEntry) {
        isBusy = true
        running = entry
        _toStart.value = entry
    }

    private companion object {
        const val TAG = "SharedEntryGate"
    }
}
