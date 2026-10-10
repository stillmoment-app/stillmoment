package com.stillmoment.presentation.navigation

import android.net.Uri
import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.LinkImportFailure
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * shared-132: Sharing links with Still Moment several times in a row never leads
 * to a message; the last shared address wins, the same address loads only once.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SharedLinkImportTest {

    private val talk25401 = "https://www.audiodharma.org/talks/25401/download"
    private val talk25402 = "https://www.audiodharma.org/talks/25402/download"

    private val downloads = FakeDownloads()
    private val editSheets = mutableListOf<LinkImportOutcome.Imported>()
    private val discarded = mutableListOf<Uri>()

    private fun TestScope.sharedLinkImport() = SharedLinkImport(
        scope = backgroundScope,
        import = downloads::import,
        cancelRunning = downloads::cancelRunning,
        onImported = { editSheets += it },
        discardDownload = { discarded += it }
    )

    private fun imported(): LinkImportOutcome.Imported =
        LinkImportOutcome.Imported(uri = mock<Uri>(), suggestion = null)

    @Nested
    inner class SameAddressTwice {

        @Test
        fun `sharing the same address again while it loads starts no second download`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, imported())
            runCurrent()

            assertEquals(listOf(talk25401), downloads.started)
            assertEquals(1, editSheets.size, "Exactly one edit sheet")
            assertNull(sut.failure.value)
        }

        @Test
        fun `sharing the same address again while it loads keeps the loading window`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25401)
            runCurrent()

            assertTrue(sut.isLoading.value)
        }

        @Test
        fun `sharing a failed address again closes the message and loads it anew`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()

            sut.share(talk25401)
            runCurrent()

            assertNull(sut.failure.value)
            assertEquals(listOf(talk25401, talk25401), downloads.started)
            assertTrue(sut.isLoading.value)
        }
    }

    @Nested
    inner class NewerAddressWhileLoading {

        @Test
        fun `a newer address replaces the loading one and is the one imported`() = runTest {
            val sut = sharedLinkImport()
            val result = imported()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25402)
            runCurrent()
            downloads.finish(talk25402, result)
            runCurrent()

            assertEquals(listOf(talk25401, talk25402), downloads.started)
            assertEquals(listOf(result), editSheets)
            assertNull(sut.failure.value)
        }

        @Test
        fun `the replaced download is stopped before the newer one starts`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25402)
            runCurrent()

            assertEquals(1, downloads.cancelCount, "The download of 25401 is stopped")
            assertEquals(1, downloads.maxParallel, "Never two downloads at the same time")
        }

        @Test
        fun `the replaced import shows no message even when it ends with an error`() = runTest {
            downloads.stopsOnCancel = false
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25402)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()

            assertNull(sut.failure.value)
            assertTrue(sut.isLoading.value, "25402 is loading now")
            assertEquals(listOf(talk25401, talk25402), downloads.started)
            assertEquals(1, downloads.maxParallel)
        }

        @Test
        fun `the loading window stays until the newer address is done`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25402)
            runCurrent()
            assertTrue(sut.isLoading.value, "Still loading after 25401 was replaced")

            downloads.finish(talk25402, imported())
            runCurrent()
            assertFalse(sut.isLoading.value)
        }

        @Test
        fun `cancelling after the replacement ends the newer import quietly`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()
            sut.share(talk25402)
            runCurrent()

            sut.cancel()
            runCurrent()

            assertFalse(sut.isLoading.value)
            assertNull(sut.failure.value)
            assertTrue(editSheets.isEmpty())
        }

        @Test
        fun `cancelling while the replaced download is still ending loads nothing new`() = runTest {
            downloads.stopsOnCancel = false
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()
            sut.share(talk25402)
            runCurrent()

            sut.cancel()
            runCurrent()
            downloads.finish(talk25401, imported())
            runCurrent()

            assertFalse(sut.isLoading.value, "Loading window closes right away")
            assertEquals(listOf(talk25401), downloads.started, "25402 is not loaded any more")
            assertTrue(editSheets.isEmpty())
            assertNull(sut.failure.value)
        }

        @Test
        fun `three addresses shared quickly import only the last and never load in parallel`() = runTest {
            downloads.stopsOnCancel = false
            val talk25403 = "https://www.audiodharma.org/talks/25403/download"
            val sut = sharedLinkImport()
            val result = imported()
            sut.share(talk25401)
            runCurrent()

            sut.share(talk25402)
            runCurrent()
            sut.share(talk25403)
            runCurrent()
            downloads.finish(talk25401, imported())
            runCurrent()
            downloads.finish(talk25403, result)
            runCurrent()

            assertEquals(listOf(talk25401, talk25403), downloads.started, "25402 never loads")
            assertEquals(1, downloads.maxParallel)
            assertEquals(listOf(result), editSheets)
        }

        @Test
        fun `a newer address replaces a running retry`() = runTest {
            downloads.stopsOnCancel = false
            val sut = sharedLinkImport()
            val result = imported()
            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()
            sut.retry()
            runCurrent()

            sut.share(talk25402)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()
            assertNull(sut.failure.value, "The replaced retry shows no message")
            downloads.finish(talk25402, result)
            runCurrent()

            assertEquals(listOf(result), editSheets)
            assertEquals(1, downloads.maxParallel)
        }
    }

    @Nested
    inner class SingleShare {

        @Test
        fun `a loaded link opens the edit sheet with the podcast suggestion`() = runTest {
            val sut = sharedLinkImport()
            val suggestion = ImportPrefill(teacher = "Deutschlandfunk Nova", name = "MBCT")
            val result = LinkImportOutcome.Imported(uri = mock<Uri>(), suggestion = suggestion)

            sut.share(talk25401)
            runCurrent()
            assertTrue(sut.isLoading.value, "Loading window while the link loads")
            downloads.finish(talk25401, result)
            runCurrent()

            assertEquals(listOf(result), editSheets)
            assertFalse(sut.isLoading.value)
            assertNull(sut.failure.value)
        }

        @Test
        fun `an unreachable address shows the message with the shared address`() = runTest {
            val sut = sharedLinkImport()

            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()

            assertEquals(FailedLinkImport(talk25401, LinkImportFailure.NotReachable), sut.failure.value)
            assertFalse(sut.isLoading.value)
            assertTrue(editSheets.isEmpty())
        }

        @Test
        fun `retry loads the same address again and opens the edit sheet`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotReachable))
            runCurrent()

            sut.retry()
            runCurrent()
            assertNull(sut.failure.value, "Message closes on retry")
            assertTrue(sut.isLoading.value)
            downloads.finish(talk25401, imported())
            runCurrent()

            assertEquals(listOf(talk25401, talk25401), downloads.started)
            assertEquals(1, editSheets.size)
        }

        @Test
        fun `dismissing the message closes it without loading again`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()
            downloads.finish(talk25401, LinkImportOutcome.Failed(LinkImportFailure.NotAudio))
            runCurrent()

            sut.dismissFailure()
            runCurrent()

            assertNull(sut.failure.value)
            assertEquals(listOf(talk25401), downloads.started)
        }

        @Test
        fun `cancelling in the loading window ends quietly`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            sut.cancel()
            runCurrent()

            assertFalse(sut.isLoading.value)
            assertNull(sut.failure.value)
            assertTrue(editSheets.isEmpty())
            assertEquals(1, downloads.cancelCount, "The running download is stopped")
        }
    }

    @Nested
    inner class DownloadsThatAreNotNeeded {

        @Test
        fun `a replaced download that still finishes loading is discarded`() = runTest {
            downloads.stopsOnCancel = false
            val sut = sharedLinkImport()
            val replaced = imported()
            val newest = imported()
            sut.share(talk25401)
            runCurrent()
            sut.share(talk25402)
            runCurrent()

            downloads.finish(talk25401, replaced)
            runCurrent()
            downloads.finish(talk25402, newest)
            runCurrent()

            assertEquals(listOf(replaced.uri), discarded)
            assertEquals(listOf(newest), editSheets)
        }

        @Test
        fun `a download that finishes right as the user cancels is discarded`() = runTest {
            downloads.stopsOnCancel = false
            val sut = sharedLinkImport()
            val late = imported()
            sut.share(talk25401)
            runCurrent()

            sut.cancel()
            runCurrent()
            downloads.finish(talk25401, late)
            runCurrent()

            assertEquals(listOf(late.uri), discarded)
            assertTrue(editSheets.isEmpty())
        }

        @Test
        fun `a loaded link handed to the edit sheet is kept`() = runTest {
            val sut = sharedLinkImport()
            sut.share(talk25401)
            runCurrent()

            downloads.finish(talk25401, imported())
            runCurrent()

            assertTrue(discarded.isEmpty())
            assertEquals(1, editSheets.size)
        }
    }

    /**
     * Stands in for the link import. Like the real download, a running import
     * only ends when it completes or [cancelRunning] stops it — cancelling the
     * coroutine alone does not stop a blocking connection.
     */
    private class FakeDownloads {
        private class Call(val url: String, val result: CompletableDeferred<LinkImportOutcome>)

        private val calls = mutableListOf<Call>()
        private var running = 0

        val started: List<String> get() = calls.map { it.url }
        var cancelCount = 0
            private set
        var maxParallel = 0
            private set

        /** When false, [cancelRunning] has no effect — the download ends on its own. */
        var stopsOnCancel = true

        suspend fun import(url: String): LinkImportOutcome {
            val call = Call(url, CompletableDeferred())
            calls += call
            running++
            maxParallel = maxOf(maxParallel, running)
            try {
                return withContext(NonCancellable) { call.result.await() }
            } finally {
                running--
            }
        }

        fun cancelRunning() {
            cancelCount++
            if (stopsOnCancel) {
                calls.filter { it.result.isActive }.forEach { it.result.complete(LinkImportOutcome.Cancelled) }
            }
        }

        fun finish(url: String, outcome: LinkImportOutcome) {
            val call = calls.lastOrNull { it.url == url && it.result.isActive }
            checkNotNull(call) { "No running download for $url" }
            call.result.complete(outcome)
        }
    }
}
