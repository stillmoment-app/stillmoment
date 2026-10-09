package com.stillmoment.presentation.util

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/** Sprachnamen in der Zeile "Auch auf Englisch" / "Also in German" (shared-137). */
class LanguageDisplayNameTest {

    @Test
    fun `German user reads the name of English in German`() {
        assertEquals("Englisch", languageDisplayName("en", inLanguageCode = "de"))
    }

    @Test
    fun `English user reads the name of German in English`() {
        assertEquals("German", languageDisplayName("de", inLanguageCode = "en"))
    }

    @Test
    fun `language name starts with a capital letter even where the system writes it in lower case`() {
        // French writes language names in lower case ("allemand").
        assertEquals("Allemand", languageDisplayName("de", inLanguageCode = "fr"))
    }
}
