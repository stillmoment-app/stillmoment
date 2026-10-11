package com.stillmoment.presentation.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.data.LinkImportHandler
import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.services.ImportDownloadsProtocol
import com.stillmoment.presentation.navigation.SharedEntry
import com.stillmoment.presentation.navigation.SharedEntryGate
import com.stillmoment.presentation.navigation.SharedLinkImport
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.launch

/**
 * A local audio file ready for the import edit sheet. [suggestion] comes from the
 * podcast import (episode title / podcast author, shared-128) and beats the
 * file's own ID3 values; `null` for file shares and ordinary links.
 */
data class SharedImport(val uri: Uri, val suggestion: ImportPrefill?)

/**
 * Activity-scoped home of everything shared with the app: links and audio
 * files, "Open with" included (shared-132, shared-138).
 *
 * Every shared entry goes through [SharedEntryGate]; this ViewModel starts what
 * the gate lets through. A link loads via [linkImport], a file goes straight to
 * [handover]. A link's import ends here when it is cancelled or its message is
 * closed; whatever reaches the library ends there with its edit sheet or message.
 *
 * Runs in [viewModelScope], so the import keeps going when the Activity is
 * re-created (dark mode, font size) and the new screen shows the same loading
 * window or message. An entry ready for the library waits in [handover] until
 * the library takes it over.
 */
@HiltViewModel
class SharedImportViewModel
@Inject
constructor(
    linkImportHandler: LinkImportHandler,
    private val importDownloads: ImportDownloadsProtocol,
    private val fileOpenHandler: FileOpenHandler,
    private val gate: SharedEntryGate
) : ViewModel() {

    private val _handover = MutableStateFlow<SharedImport?>(null)

    /** A loaded link or shared file the library has not taken over yet. */
    val handover: StateFlow<SharedImport?> = _handover.asStateFlow()

    /** Loading window, message, "Retry" and "Cancel" of a shared link. */
    val linkImport = SharedLinkImport(
        scope = viewModelScope,
        import = linkImportHandler::import,
        cancelRunning = linkImportHandler::cancel,
        onImported = ::handOverLink,
        onEnded = gate::importEnded,
        discardDownload = { importDownloads.discard(it.toString()) }
    )

    init {
        viewModelScope.launch {
            gate.toStart.filterNotNull().collect(::start)
        }
    }

    /** A link was shared with the app. */
    fun shareLink(url: String) {
        gate.share(SharedEntry.Link(url))
    }

    /** An audio file of a supported format was shared or opened with the app. */
    fun shareFile(uri: Uri) {
        gate.share(
            SharedEntry.File(
                uri = uri,
                fileName = fileOpenHandler.getFileName(uri),
                sizeBytes = fileOpenHandler.getFileSize(uri)
            )
        )
    }

    /** The library took the entry over and opens its edit sheet. */
    fun consumeHandover() {
        _handover.value = null
    }

    private fun start(entry: SharedEntry) {
        gate.started()
        when (entry) {
            is SharedEntry.Link -> linkImport.start(entry.url)
            is SharedEntry.File -> _handover.value = SharedImport(uri = entry.uri, suggestion = null)
        }
    }

    private fun handOverLink(imported: LinkImportOutcome.Imported) {
        _handover.value = SharedImport(uri = imported.uri, suggestion = imported.suggestion)
    }
}
