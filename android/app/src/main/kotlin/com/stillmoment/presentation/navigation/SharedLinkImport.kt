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
 * Imports shared links one at a time while the loading window is shown (shared-132).
 *
 * Rule: the last shared address wins. Sharing the address that is loading right
 * now changes nothing; any other address replaces the running import. "Retry"
 * runs through the same rule, so a newer share replaces it as well.
 *
 * Plain class instead of Compose state so the rule is unit-testable — same
 * pattern as [PlayerCompletionWiring].
 *
 * @param import Loads a shared address into a local file (`LinkImportHandler::import`).
 * @param cancelRunning Stops the running lookup/download (`LinkImportHandler::cancel`).
 * @param onImported Hands a loaded file over to the edit sheet.
 * @param discardDownload Frees a loaded file nobody takes over any more (android-087).
 */
class SharedLinkImport(
    private val scope: CoroutineScope,
    private val import: suspend (String) -> LinkImportOutcome,
    private val cancelRunning: () -> Unit,
    private val onImported: (LinkImportOutcome.Imported) -> Unit,
    private val discardDownload: suspend (Uri) -> Unit
) {
    private val _isLoading = MutableStateFlow(false)

    /** True while the loading window is to be shown. */
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _failure = MutableStateFlow<FailedLinkImport?>(null)

    /** The message to show, or `null`. */
    val failure: StateFlow<FailedLinkImport?> = _failure.asStateFlow()

    private var job: Job? = null
    private var loadingUrl: String? = null

    /** A link was shared with the app. */
    fun share(url: String) {
        if (url == loadingUrl) {
            return
        }
        start(url)
    }

    /** "Retry" in the message: load the failed address again. */
    fun retry() {
        val failed = _failure.value ?: return
        start(failed.sharedUrl)
    }

    /** The message was closed without retrying. */
    fun dismissFailure() {
        _failure.value = null
    }

    /**
     * "Cancel" in the loading window — ends quietly, no message, nothing is
     * imported. Also holds when the newest import is still waiting for a
     * replaced download to end.
     */
    fun cancel() {
        if (!_isLoading.value) {
            return
        }
        cancelRunning()
        job?.cancel()
        loadingUrl = null
        _isLoading.value = false
    }

    /**
     * Replaces whatever runs with an import of [url].
     *
     * The previous download is stopped via [cancelRunning] — cancelling the
     * coroutine alone does not end a blocking connection — and the new import
     * only starts once the previous one has really ended. So there is never more
     * than one download, and the replaced one can neither show a message nor
     * reset the state the newer one relies on.
     */
    private fun start(url: String) {
        _failure.value = null
        val previous = job
        if (previous?.isActive == true) {
            cancelRunning()
            previous.cancel()
        }
        loadingUrl = url
        _isLoading.value = true
        job = scope.launch {
            // Even when this import is replaced in turn, wait for the previous one:
            // otherwise a third share could start while the first still downloads.
            withContext(NonCancellable) { previous?.join() }
            ensureActive()
            val outcome = import(url)
            if (!isActive) {
                // Replaced or cancelled while the download was ending: nobody takes
                // the file over, so it must not stay on the device (android-087).
                if (outcome is LinkImportOutcome.Imported) {
                    withContext(NonCancellable) { discardDownload(outcome.uri) }
                }
                return@launch
            }
            loadingUrl = null
            _isLoading.value = false
            when (outcome) {
                is LinkImportOutcome.Imported -> onImported(outcome)
                is LinkImportOutcome.Failed -> _failure.value = FailedLinkImport(url, outcome.failure)
                LinkImportOutcome.Cancelled -> Unit
            }
        }
    }
}
