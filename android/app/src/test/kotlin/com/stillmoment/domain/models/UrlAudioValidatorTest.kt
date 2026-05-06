package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for UrlAudioValidator.
 *
 * Since shared-091 the validator only checks the URL scheme — the actual
 * audio decision is made by the downloader against the server's Content-Type.
 */
class UrlAudioValidatorTest {

    @Nested
    inner class IsAudioUrl {

        @Test
        fun `accepts https mp3 url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/meditation.mp3"))
        }

        @Test
        fun `accepts https m4a url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/session.m4a"))
        }

        @Test
        fun `accepts http url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("http://example.com/audio.mp3"))
        }

        @Test
        fun `accepts mp3 url with query parameters`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://cdn.example.com/file.mp3?token=abc&expires=123"))
        }

        @Test
        fun `accepts mp3 url with fragment`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/meditation.mp3#section"))
        }

        @Test
        fun `accepts uppercase extension`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/audio.MP3"))
        }

        @Test
        fun `accepts url without recognisable extension`() {
            // shared-091: audio CDNs often serve files behind redirect URLs without
            // .mp3/.m4a in the path (e.g. audiodharma.org/talks/25401/download).
            // The Content-Type check at download time decides whether it's audio.
            assertTrue(UrlAudioValidator.isAudioUrl("https://www.audiodharma.org/talks/25401/download"))
        }

        @Test
        fun `accepts url without path`() {
            // Validation is now scheme-only; the download attempt itself decides.
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/"))
        }

        @Test
        fun `accepts url that points to non-audio resource`() {
            // The validator can't know upfront — it's scheme-only since shared-091.
            // The downloader will reject text/html with NotAudio.
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/page.html"))
        }

        @Test
        fun `rejects file scheme`() {
            assertFalse(UrlAudioValidator.isAudioUrl("file:///local/meditation.mp3"))
        }

        @Test
        fun `rejects blank string`() {
            assertFalse(UrlAudioValidator.isAudioUrl(""))
        }

        @Test
        fun `rejects content scheme`() {
            assertFalse(UrlAudioValidator.isAudioUrl("content://media/audio/123"))
        }

        @Test
        fun `rejects ftp scheme`() {
            assertFalse(UrlAudioValidator.isAudioUrl("ftp://example.com/audio.mp3"))
        }
    }

    @Nested
    inner class ClassifyShareText {
        // shared-091 silent-fail guard: Wenn der User aktiv "Still Moment"
        // im Share-Sheet waehlt, MUSS ein User-sichtbares Resultat folgen.
        // Diese Klassifikation entscheidet zwischen "Download starten" und
        // "Snackbar 'kein Link erkannt'" — niemals stilles Verschwinden.

        @Test
        fun `null text returns NotALink`() {
            assertEquals(
                UrlAudioValidator.ShareTextResult.NotALink,
                UrlAudioValidator.classifyShareText(null)
            )
        }

        @Test
        fun `blank text returns NotALink`() {
            assertEquals(
                UrlAudioValidator.ShareTextResult.NotALink,
                UrlAudioValidator.classifyShareText("")
            )
        }

        @Test
        fun `whitespace-only text returns NotALink`() {
            assertEquals(
                UrlAudioValidator.ShareTextResult.NotALink,
                UrlAudioValidator.classifyShareText("   ")
            )
        }

        @Test
        fun `plain text without scheme returns NotALink`() {
            assertEquals(
                UrlAudioValidator.ShareTextResult.NotALink,
                UrlAudioValidator.classifyShareText("Hello World")
            )
        }

        @Test
        fun `mailto scheme returns NotALink`() {
            assertEquals(
                UrlAudioValidator.ShareTextResult.NotALink,
                UrlAudioValidator.classifyShareText("mailto:foo@bar.com")
            )
        }

        @Test
        fun `https url returns AudioUrl with same url`() {
            val url = "https://example.com/meditation.mp3"
            assertEquals(
                UrlAudioValidator.ShareTextResult.AudioUrl(url),
                UrlAudioValidator.classifyShareText(url)
            )
        }

        @Test
        fun `http url returns AudioUrl`() {
            val url = "http://example.com/meditation.mp3"
            assertEquals(
                UrlAudioValidator.ShareTextResult.AudioUrl(url),
                UrlAudioValidator.classifyShareText(url)
            )
        }

        @Test
        fun `https url without recognisable extension returns AudioUrl`() {
            // shared-091 main case: redirect-URL ohne Endung ist trotzdem AudioUrl
            val url = "https://www.audiodharma.org/talks/25401/download"
            assertEquals(
                UrlAudioValidator.ShareTextResult.AudioUrl(url),
                UrlAudioValidator.classifyShareText(url)
            )
        }
    }

    @Nested
    inner class ExtractFilename {

        @Test
        fun `extracts filename from simple url`() {
            assertEquals("meditation.mp3", UrlAudioValidator.extractFilename("https://example.com/meditation.mp3"))
        }

        @Test
        fun `extracts filename from url with path segments`() {
            val url = "https://cdn.example.com/audio/2024/session.m4a"
            assertEquals("session.m4a", UrlAudioValidator.extractFilename(url))
        }

        @Test
        fun `strips query parameters from filename`() {
            assertEquals("file.mp3", UrlAudioValidator.extractFilename("https://example.com/file.mp3?token=abc"))
        }

        @Test
        fun `strips fragment from filename`() {
            assertEquals("audio.mp3", UrlAudioValidator.extractFilename("https://example.com/audio.mp3#section"))
        }

        @Test
        fun `returns fallback for url without filename`() {
            val result = UrlAudioValidator.extractFilename("https://example.com/")
            assertTrue(result.isNotBlank())
        }
    }
}
