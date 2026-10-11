package com.stillmoment.presentation.navigation

import android.net.Uri
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * shared-138: What the app has begun (loading, edit sheet, message) it finishes.
 * An entry shared meanwhile waits and starts on its own afterwards. At most one
 * entry waits; among the waiting ones the last shared wins.
 */
class SharedEntryGateTest {

    private val talk25401 = SharedEntry.Link("https://www.audiodharma.org/talks/25401/download")
    private val talk25402 = SharedEntry.Link("https://www.audiodharma.org/talks/25402/download")
    private val bodyScan = SharedEntry.File(uri = mock<Uri>(), fileName = "body-scan.mp3", sizeBytes = 4_200_000L)

    private val sut = SharedEntryGate(logger = mock())

    /** What the starter does: take the entry over and begin its import. */
    private fun takeOverStartingEntry(): SharedEntry? = sut.toStart.value?.also { sut.started() }

    @Nested
    inner class NothingRuns {

        @Test
        fun `a shared entry starts right away`() {
            sut.share(talk25401)

            assertEquals(talk25401, takeOverStartingEntry())
        }

        @Test
        fun `after the import ended the next shared entry starts right away`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.importEnded()

            sut.share(talk25402)

            assertEquals(talk25402, takeOverStartingEntry())
        }
    }

    @Nested
    inner class SharedWhileAnImportRuns {

        @Test
        fun `a link shared while another link loads waits`() {
            sut.share(talk25401)
            takeOverStartingEntry()

            sut.share(talk25402)

            assertNull(sut.toStart.value, "25401 is not replaced")
        }

        @Test
        fun `the waiting entry starts once the running import has ended`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.share(bodyScan)

            sut.importEnded()

            assertEquals(bodyScan, takeOverStartingEntry())
        }

        @Test
        fun `of several entries shared meanwhile only the last starts`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.share(talk25402)
            sut.share(bodyScan)

            sut.importEnded()

            assertEquals(bodyScan, takeOverStartingEntry())
            sut.importEnded()
            assertNull(sut.toStart.value, "25402 never starts")
        }

        @Test
        fun `the entry that started after waiting holds back further shares until it ends`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.share(talk25402)
            sut.importEnded()
            takeOverStartingEntry()

            sut.share(bodyScan)

            assertNull(sut.toStart.value)
            sut.importEnded()
            assertEquals(bodyScan, takeOverStartingEntry())
        }

        @Test
        fun `an entry shared before the starter took the previous one over waits as well`() {
            sut.share(talk25401)

            sut.share(talk25402)

            assertEquals(talk25401, takeOverStartingEntry())
            sut.importEnded()
            assertEquals(talk25402, takeOverStartingEntry())
        }
    }

    @Nested
    inner class SameEntryAgain {

        @Test
        fun `the running link shared again is ignored and nothing waits afterwards`() {
            sut.share(talk25401)
            takeOverStartingEntry()

            sut.share(talk25401)
            sut.importEnded()

            assertNull(sut.toStart.value, "No second import, no late \"already there\"")
        }

        @Test
        fun `the running link shared again leaves a different waiting entry alone`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.share(talk25402)

            sut.share(talk25401)
            sut.importEnded()

            assertEquals(talk25402, takeOverStartingEntry())
        }

        @Test
        fun `the running file handed over again under a new address is ignored`() {
            sut.share(bodyScan)
            takeOverStartingEntry()

            sut.share(bodyScan.copy(uri = mock<Uri>()))
            sut.importEnded()

            assertNull(sut.toStart.value)
        }

        @Test
        fun `a different file with the same name but another size waits`() {
            sut.share(bodyScan)
            takeOverStartingEntry()
            val otherBodyScan = bodyScan.copy(uri = mock<Uri>(), sizeBytes = 9_100_000L)

            sut.share(otherBodyScan)
            sut.importEnded()

            assertEquals(otherBodyScan, takeOverStartingEntry())
        }

        @Test
        fun `two files of unknown size with the same name are different entries`() {
            val unknownFirst = SharedEntry.File(uri = mock<Uri>(), fileName = "Unknown", sizeBytes = null)
            val unknownSecond = SharedEntry.File(uri = mock<Uri>(), fileName = "Unknown", sizeBytes = null)
            sut.share(unknownFirst)
            takeOverStartingEntry()

            sut.share(unknownSecond)
            sut.importEnded()

            assertEquals(unknownSecond, takeOverStartingEntry())
        }

        @Test
        fun `an entry shared again only after its import ended starts again`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.importEnded()

            sut.share(talk25401)

            assertEquals(talk25401, takeOverStartingEntry(), "The library then says \"already there\"")
        }
    }

    @Nested
    inner class ImportWithoutSharing {

        @Test
        fun `an open edit sheet holds back a shared link until it is closed`() {
            sut.importBegan()

            sut.share(talk25402)

            assertNull(sut.toStart.value)
            sut.importEnded()
            assertEquals(talk25402, takeOverStartingEntry())
        }

        @Test
        fun `an edit sheet opened during a shared import does not end anything`() {
            sut.share(talk25401)
            takeOverStartingEntry()
            sut.share(talk25402)

            sut.importBegan()

            assertNull(sut.toStart.value)
            sut.importEnded()
            assertEquals(talk25402, takeOverStartingEntry())
        }

        @Test
        fun `once the edit sheet is closed the next share starts right away`() {
            sut.importBegan()
            sut.importEnded()

            sut.share(talk25401)

            assertEquals(talk25401, takeOverStartingEntry())
        }

        @Test
        fun `an end reported while nothing runs changes nothing`() {
            sut.importEnded()

            sut.share(talk25401)

            assertEquals(talk25401, takeOverStartingEntry())
        }
    }
}
