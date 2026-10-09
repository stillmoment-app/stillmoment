package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Fachliche Tests fuer die Sprachgruppen der Quellenliste in "Wo finde ich Meditationen?"
 * (shared-137): eigene Sprache zuerst, dann Englisch, dann uebrige alphabetisch nach
 * angezeigtem Sprachnamen. Innerhalb einer Sprache bleibt die Reihenfolge des Katalogs.
 */
class MeditationSourceCatalogTest {

    private val catalog = MeditationSourceCatalog(
        mapOf(
            "de" to listOf(source("koeln"), source("braehler")),
            "en" to listOf(source("audio-dharma"), source("tara-brach"))
        )
    )

    /** Sprachnamen wie auf einem deutschen Geraet. */
    private val germanNames: (String) -> String = { code ->
        when (code) {
            "de" -> "Deutsch"
            "en" -> "Englisch"
            "fr" -> "Französisch"
            "es" -> "Spanisch"
            "it" -> "Italienisch"
            else -> code
        }
    }

    @Test
    fun `German user sees German sources first, then English`() {
        val groups = catalog.groups(ownLanguageCode = "de", displayName = germanNames)

        assertEquals(listOf("de", "en"), groups.map { it.languageCode })
    }

    @Test
    fun `English user sees English sources first, then German`() {
        val groups = catalog.groups(ownLanguageCode = "en", displayName = germanNames)

        assertEquals(listOf("en", "de"), groups.map { it.languageCode })
    }

    @Test
    fun `user with a language without sources gets English as own language`() {
        val groups = catalog.groups(ownLanguageCode = "fr", displayName = germanNames)

        assertEquals(listOf("en", "de"), groups.map { it.languageCode })
    }

    @Test
    fun `further languages follow English alphabetically by displayed name`() {
        val many = MeditationSourceCatalog(
            mapOf(
                "it" to listOf(source("it-1")),
                "de" to listOf(source("de-1")),
                "es" to listOf(source("es-1")),
                "en" to listOf(source("en-1")),
                "fr" to listOf(source("fr-1"))
            )
        )

        val groups = many.groups(ownLanguageCode = "de", displayName = germanNames)

        // Französisch < Italienisch < Spanisch
        assertEquals(listOf("de", "en", "fr", "it", "es"), groups.map { it.languageCode })
    }

    @Test
    fun `order of sources within a language stays as in the catalog`() {
        val groups = catalog.groups(ownLanguageCode = "de", displayName = germanNames)

        assertEquals(listOf("koeln", "braehler"), groups[0].sources.map { it.id })
        assertEquals(listOf("audio-dharma", "tara-brach"), groups[1].sources.map { it.id })
    }

    @Test
    fun `languages without sources are left out`() {
        val withEmpty = MeditationSourceCatalog(
            mapOf(
                "de" to listOf(source("koeln")),
                "en" to emptyList(),
                "fr" to listOf(source("fr-1"))
            )
        )

        val groups = withEmpty.groups(ownLanguageCode = "de", displayName = germanNames)

        assertEquals(listOf("de", "fr"), groups.map { it.languageCode })
    }

    @Test
    fun `empty catalog shows no groups`() {
        val groups = MeditationSourceCatalog(emptyMap()).groups(ownLanguageCode = "de", displayName = germanNames)

        assertTrue(groups.isEmpty())
    }

    private fun source(id: String) = MeditationSource(
        id = id,
        name = id,
        offer = null,
        description = "desc",
        host = "example.com",
        url = "https://example.com/$id"
    )
}
