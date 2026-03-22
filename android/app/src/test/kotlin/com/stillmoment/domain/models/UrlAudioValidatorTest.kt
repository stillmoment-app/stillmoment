package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for UrlAudioValidator.
 *
 * Validates that audio URLs (MP3/M4A via HTTP/HTTPS) are correctly identified
 * and non-audio URLs are silently rejected.
 */
class UrlAudioValidatorTest {

    @Nested
    inner class IsAudioUrl {

        @Test
        fun `returns true for https mp3 url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/meditation.mp3"))
        }

        @Test
        fun `returns true for https m4a url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/session.m4a"))
        }

        @Test
        fun `returns true for http mp3 url`() {
            assertTrue(UrlAudioValidator.isAudioUrl("http://example.com/audio.mp3"))
        }

        @Test
        fun `returns true for mp3 url with query parameters`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://cdn.example.com/file.mp3?token=abc&expires=123"))
        }

        @Test
        fun `returns true for mp3 url with fragment`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/meditation.mp3#section"))
        }

        @Test
        fun `returns true for mp3 url with path segments`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://cdn.example.com/meditations/2024/long-path/session.mp3"))
        }

        @Test
        fun `returns true for uppercase extension`() {
            assertTrue(UrlAudioValidator.isAudioUrl("https://example.com/audio.MP3"))
        }

        @Test
        fun `returns false for non-audio extension`() {
            assertFalse(UrlAudioValidator.isAudioUrl("https://example.com/page.html"))
        }

        @Test
        fun `returns false for url without path`() {
            assertFalse(UrlAudioValidator.isAudioUrl("https://example.com/"))
        }

        @Test
        fun `returns false for url with no extension`() {
            assertFalse(UrlAudioValidator.isAudioUrl("https://example.com/meditation"))
        }

        @Test
        fun `returns false for file scheme`() {
            assertFalse(UrlAudioValidator.isAudioUrl("file:///local/meditation.mp3"))
        }

        @Test
        fun `returns false for blank string`() {
            assertFalse(UrlAudioValidator.isAudioUrl(""))
        }

        @Test
        fun `returns false for youtube url`() {
            assertFalse(UrlAudioValidator.isAudioUrl("https://youtube.com/watch?v=abc123"))
        }

        @Test
        fun `returns false for pdf url`() {
            assertFalse(UrlAudioValidator.isAudioUrl("https://example.com/document.pdf"))
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
