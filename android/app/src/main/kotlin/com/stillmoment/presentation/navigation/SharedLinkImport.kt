package com.stillmoment.presentation.navigation

import android.net.Uri
import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.domain.models.LinkImportFailure
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** A failed link import plus the shared address, so "Retry" can run the whole import again. */
data class FailedLinkImport(val sharedUrl: String, val failure: LinkImportFailure)

/**
 * Loads a shared link while the loading window is shown, with message, "Retry"
 * and "Cancel" (shared-128, shared-132).
 *
 * Which link loads when is not decided here: [SharedEntryGate] starts a link
 * only when no other import runs (shared-138). This class reports every way the
 * import ends without an edit sheet via `onEnded` — "Cancel", closing the
 * message, a download stopped from elsewhere. "Retry" continues the same import.
 *
 * Plain class instead of Compose state so it is unit-testable — same pattern as
 * [PlayerCompletionWiring].
 *
 * @param import Loads a shared address into a local file (`LinkImportHandler::import`).
 * @param cancelRunning Stops the running lookup/download (`LinkImportHandler::cancel`).
 * @param onImported Hands a loaded file over to the edit sheet, which ends the import later.
 * @param onEnded The import ended without an edit sheet.
 * @param discardDownload Frees a loaded file nobody takes over any more (android-087).
 */
class SharedLinkImport(
    private val scope: CoroutineScope,
    private val import: suspend (String) -> LinkImportOutcome,
    private val cancelRunning: () -> Unit,
    private val onImported: (LinkImportOutcome.Imported) -> Unit,
    private val onEnded: () -> Unit,
    private val discardDownload: suspend (Uri) -> Unit
) {
    private val _isLoading = MutableStateFlow(false)

    /** True while the loading window is to be shown. */
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _failure = MutableStateFlow<FailedLinkImport?>(null)

    /** The message to show, or `null`. */
    val failure: StateFlow<FailedLinkImport?> = _failure.asStateFlow()

    private var job: Job? = null

    /** "Retry" in the message: load the failed address again. */
    fun retry() {
        val failed = _failure.value ?: return
        start(failed.sharedUrl)
    }

    /** The message was closed without retrying — the import ends here. */
    fun dismissFailure() {
        if (_failure.value == null) {
            return
        }
        _failure.value = null
        onEnded()
    }

    /** "Cancel" in the loading window — ends quietly, no message, nothing is imported. */
    fun cancel() {
        if (!_isLoading.value) {
            return
        }
        cancelRunning()
        job?.cancel()
        _isLoading.value = false
        onEnded()
    }

    /**
     * Loads [url] with the loading window shown.
     *
     * After "Cancel" the cancelled download may still be ending — cancelling the
     * coroutine alone does not end a blocking connection. The new import only
     * starts once it has really ended, so there is never more than one download.
     */
    fun start(url: String) {
        _failure.value = null
        val previous = job
        _isLoading.value = true
        job = scope.launch {
            withContext(NonCancellable) { previous?.join() }
            ensureActive()
            val outcome = import(url)
            if (!isActive) {
                // Cancelled while the download was ending: nobody takes the file
                // over, so it must not stay on the device (android-087).
                if (outcome is LinkImportOutcome.Imported) {
                    withContext(NonCancellable) { discardDownload(outcome.uri) }
                }
                return@launch
            }
            _isLoading.value = false
            when (outcome) {
                is LinkImportOutcome.Imported -> onImported(outcome)
                is LinkImportOutcome.Failed -> _failure.value = FailedLinkImport(url, outcome.failure)
                LinkImportOutcome.Cancelled -> onEnded()
            }
        }
    }
}
