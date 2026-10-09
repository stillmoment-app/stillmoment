package com.stillmoment.domain.models

import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Addresses behind the feedback rows in the settings' info section (shared-134).
 *
 * The app never asks for a review on its own — "Rate the App" opens the Google Play page,
 * "Write to Us" opens a prepared mail in the person's mail app.
 */
object FeedbackLinks {
    /**
     * Fixed package name of the store listing. Debug builds run as `com.stillmoment.dev`,
     * which has no store page — so this is deliberately not derived from the build.
     */
    private const val STORE_PACKAGE = "com.stillmoment"

    /** Address that receives messages from "Write to Us". */
    const val MAIL_ADDRESS = "hello@stillmoment.app"

    /** Brand name, intentionally not localized. */
    const val MAIL_SUBJECT = "Still Moment"

    /** Google Play app page of Still Moment. */
    const val STORE_URI = "market://details?id=$STORE_PACKAGE"

    /** Fallback when no Play Store app is installed: the same page in the browser. */
    const val STORE_WEB_URL = "https://play.google.com/store/apps/details?id=$STORE_PACKAGE"

    /**
     * Mail text: two empty lines (room to write), then app version, build and Android version —
     * visible before sending and deletable by the person.
     */
    fun mailBody(appVersion: String, buildNumber: String, osVersion: String): String =
        "\n\nStill Moment $appVersion ($buildNumber) · Android $osVersion"

    /**
     * A new mail to [MAIL_ADDRESS] with subject and [mailBody] as `mailto` URI (RFC 6068).
     *
     * Values are percent-encoded so that only unreserved characters (letters, digits, `-._~`)
     * stay literal: `+`, `&` and `=` in the version cannot break the query, spaces become `%20`
     * (never `+`), line breaks `%0A`.
     */
    fun mailtoUri(appVersion: String, buildNumber: String, osVersion: String): String {
        val subject = percentEncoded(MAIL_SUBJECT)
        val body = percentEncoded(mailBody(appVersion, buildNumber, osVersion))
        return "mailto:$MAIL_ADDRESS?subject=$subject&body=$body"
    }

    /**
     * [URLEncoder] uses form encoding: it keeps `*` literal and turns spaces into `+`.
     * Both are corrected so the result contains only unreserved characters plus escapes.
     */
    private fun percentEncoded(value: String): String = URLEncoder.encode(value, StandardCharsets.UTF_8.name())
        .replace("+", "%20")
        .replace("*", "%2A")
}
