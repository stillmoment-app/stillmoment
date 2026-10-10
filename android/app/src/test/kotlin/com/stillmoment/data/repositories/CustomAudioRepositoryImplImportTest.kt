package com.stillmoment.data.repositories

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import com.stillmoment.data.local.CustomAudioDataStore
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.services.AudioDurationProbe
import java.io.ByteArrayInputStream
import java.io.File
import java.nio.file.Path
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Importing a long custom audio file must not wait for the play-length detection
 * (android-079): the file is saved and listed right away, the length follows later.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class CustomAudioRepositoryImplImportTest {
    @TempDir
    lateinit var filesDir: Path

    private val context: Context = mock()
    private val contentResolver: ContentResolver = mock()
    private val dataStore: CustomAudioDataStore = mock()
    private val sourceUri: Uri = mock()
    private val probedPaths = mutableListOf<String>()
    private var probeAnswer = CompletableDeferred<Long?>()

    private val probe = object : AudioDurationProbe {
        override suspend fun durationMs(filePath: String): Long? {
            probedPaths += filePath
            return probeAnswer.await()
        }
    }

    @BeforeEach
    fun setUp() {
        whenever(context.contentResolver).thenReturn(contentResolver)
        whenever(context.filesDir).thenReturn(filesDir.toFile())
        whenever(contentResolver.openInputStream(sourceUri))
            .thenReturn(ByteArrayInputStream(ByteArray(AUDIO_BYTES)))
    }

    private fun TestScope.repository() = CustomAudioRepositoryImpl(
        context = context,
        dataStore = dataStore,
        durationBackfill = CustomAudioDurationBackfill(
            probe = probe,
            storeDuration = { id, durationMs -> dataStore.updateDuration(id, durationMs) },
            scope = backgroundScope,
            timeoutMs = 60_000L
        )
    )

    @Test
    fun `imported file is listed before its play length is known`() = runTest {
        val result = repository().importFile(sourceUri, CustomAudioType.SOUNDSCAPE)

        val imported = result.getOrThrow()
        assertNull(imported.durationMs)
        val saved = argumentCaptor<CustomAudioFile>()
        verify(dataStore).addFile(saved.capture())
        assertEquals(imported, saved.firstValue)
        verify(dataStore, never()).updateDuration(any(), any())
    }

    @Test
    fun `play length is detected on the imported copy and added afterwards`() = runTest {
        val imported = repository().importFile(sourceUri, CustomAudioType.SOUNDSCAPE).getOrThrow()

        probeAnswer.complete(1_800_000L)
        runCurrent()

        verify(dataStore).updateDuration(eq(imported.id), eq(1_800_000L))
        val copy = File(probedPaths.single())
        assertEquals(imported.filename, copy.name)
        assertTrue(copy.exists())
    }

    @Test
    fun `failed play length detection leaves the imported file without length`() = runTest {
        val imported = repository().importFile(sourceUri, CustomAudioType.SOUNDSCAPE).getOrThrow()

        probeAnswer.complete(null)
        runCurrent()

        assertNull(imported.durationMs)
        verify(dataStore, never()).updateDuration(any(), any())
    }

    private companion object {
        const val AUDIO_BYTES = 4_096
    }
}
