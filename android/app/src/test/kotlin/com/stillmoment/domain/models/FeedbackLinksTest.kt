package com.stillmoment.domain.models

import java.net.URI
import java.net.URLDecoder
import java.nio.charset.StandardCharsets
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * shared-134: "App bewerten" (Google Play) und "Schreib uns" (Mail an hello@stillmoment.app).
 */
class FeedbackLinksTest {

    @Nested
    inner class RateApp {

        @Test
        fun `rate app opens Still Moment in Google Play, also from debug builds`() {
            assertEquals("market://details?id=com.stillmoment", FeedbackLinks.STORE_URI)
            assertFalse(FeedbackLinks.STORE_URI.contains(".dev"))
        }

        @Test
        fun `without Play Store app the browser opens the Google Play page of Still Moment`() {
            assertEquals(
                "https://play.google.com/store/apps/details?id=com.stillmoment",
                FeedbackLinks.STORE_WEB_URL
            )
        }
    }

    @Nested
    inner class WriteToUs {

        @Test
        fun `mail is addressed to Still Moment`() {
            val uri = URI(writeToUsUri())

            assertEquals("mailto", uri.scheme)
            assertEquals("hello@stillmoment.app", uri.rawSchemeSpecificPart.substringBefore("?"))
            assertEquals("hello@stillmoment.app", FeedbackLinks.MAIL_ADDRESS)
        }

        @Test
        fun `mail has subject Still Moment`() {
            assertEquals("Still Moment", FeedbackLinks.MAIL_SUBJECT)
            assertEquals("Still Moment", queryValue(writeToUsUri(), "subject"))
        }

        @Test
        fun `body starts with two empty lines followed by the version line`() {
            val body = FeedbackLinks.mailBody(appVersion = "2.5.0", buildNumber = "20", osVersion = "15")

            assertEquals("\n\nStill Moment 2.5.0 (20) · Android 15", body)
        }

        @Test
        fun `mailto decodes back to exactly subject and body`() {
            val uri = writeToUsUri()

            assertEquals(listOf("subject", "body"), queryNames(uri))
            assertEquals(FeedbackLinks.MAIL_SUBJECT, queryValue(uri, "subject"))
            assertEquals(
                FeedbackLinks.mailBody(appVersion = "2.5.0", buildNumber = "20", osVersion = "15"),
                queryValue(uri, "body")
            )
        }

        @Test
        fun `spaces are encoded as percent 20, never as plus`() {
            val uri = writeToUsUri()

            assertTrue(uri.contains("subject=Still%20Moment"), uri)
            assertFalse(uri.contains("+"), uri)
        }

        @Test
        fun `line breaks are encoded`() {
            val uri = writeToUsUri()

            assertTrue(uri.contains("body=%0A%0AStill%20Moment"), uri)
            assertFalse(uri.contains("\n"), uri)
        }

        @Test
        fun `version with special characters survives unchanged`() {
            val uri = writeToUsUri(appVersion = "2.5.0-beta+1&x=y")

            assertEquals(listOf("subject", "body"), queryNames(uri))
            assertEquals("\n\nStill Moment 2.5.0-beta+1&x=y (20) · Android 15", queryValue(uri, "body"))
        }

        private fun writeToUsUri(appVersion: String = "2.5.0"): String =
            FeedbackLinks.mailtoUri(appVersion = appVersion, buildNumber = "20", osVersion = "15")

        private fun queryPairs(uri: String): List<Pair<String, String>> =
            uri.substringAfter("?").split("&").map { pair ->
                val name = pair.substringBefore("=")
                // URLDecoder would turn "+" into a space; the encoder never emits a raw "+",
                // so protect literal plus signs to make the round trip strict.
                val rawValue = pair.substringAfter("=").replace("+", "%2B")
                name to URLDecoder.decode(rawValue, StandardCharsets.UTF_8.name())
            }

        private fun queryNames(uri: String): List<String> = queryPairs(uri).map { it.first }

        private fun queryValue(uri: String, name: String): String? =
            queryPairs(uri).firstOrNull { it.first == name }?.second
    }
}
