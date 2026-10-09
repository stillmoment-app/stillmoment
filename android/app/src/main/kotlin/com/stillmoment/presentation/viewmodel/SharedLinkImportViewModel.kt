package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.data.LinkImportHandler
import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.presentation.navigation.SharedLinkImport
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Activity-scoped home of the shared-link import (shared-132).
 *
 * The import runs in [viewModelScope], so it keeps going when the Activity is
 * re-created (dark mode, font size) and the new screen shows the same loading
 * window or message. A link that finishes loading meanwhile waits in
 * [importedLink] until the screen opens the edit sheet.
 */
@HiltViewModel
class SharedLinkImportViewModel
@Inject
constructor(
    linkImportHandler: LinkImportHandler
) : ViewModel() {

    private val _importedLink = MutableStateFlow<LinkImportOutcome.Imported?>(null)

    /** A loaded link the edit sheet has not taken over yet. */
    val importedLink: StateFlow<LinkImportOutcome.Imported?> = _importedLink.asStateFlow()

    /** Share, retry, cancel, loading window and message. */
    val linkImport = SharedLinkImport(
        scope = viewModelScope,
        import = linkImportHandler::import,
        cancelRunning = linkImportHandler::cancel,
        onImported = { _importedLink.value = it }
    )

    /** The edit sheet took the loaded link over. */
    fun consumeImportedLink() {
        _importedLink.value = null
    }
}
