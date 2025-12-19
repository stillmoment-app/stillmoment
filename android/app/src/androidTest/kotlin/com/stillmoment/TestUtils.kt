package com.stillmoment

import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.SemanticsNodeInteractionsProvider
import androidx.compose.ui.test.hasText

/**
 * Test utility functions for UI tests.
 */

/**
 * Finds a node with text matching the given string, ignoring case.
 * Useful for testing localized text that might have different casing.
 *
 * @param text The text to search for (case insensitive)
 * @return SemanticsNodeInteraction for the matching node
 */
fun SemanticsNodeInteractionsProvider.onNodeWithTextIgnoreCase(
    text: String
): SemanticsNodeInteraction = onNode(hasText(text, ignoreCase = true))

/**
 * Checks if a node with the given text exists.
 * Does not throw an exception if the node doesn't exist.
 *
 * @param text The text to search for
 * @return true if the node exists, false otherwise
 */
fun SemanticsNodeInteractionsProvider.nodeWithTextExists(text: String): Boolean {
    return try {
        onNode(hasText(text)).fetchSemanticsNode()
        true
    } catch (e: AssertionError) {
        false
    }
}
