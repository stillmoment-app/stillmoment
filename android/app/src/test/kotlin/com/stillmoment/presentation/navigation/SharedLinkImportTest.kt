package com.stillmoment.presentation.navigation

import android.net.Uri
import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.LinkImportFailure
import kotlinx.coroutines.CompletableDeferred
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
class SharedLinkImportTest {

    private val talk25401 = "https://www.audiodharma.org/talks/25401/download"

    private val downloads = FakeDownloads()
    private val editSheets = mutableListOf<LinkImportOutcome.Imported>()

    private fun TestScope.sharedLinkImport() = SharedLinkImport(
        scope = backgroundScope,
        import = downloads::import,
        cancelRunning = downloads::cancelRunning,
        onImported = { editSheets += it }
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
