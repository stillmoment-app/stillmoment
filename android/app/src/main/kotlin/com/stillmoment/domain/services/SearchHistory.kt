package com.stillmoment.domain.services

import java.text.Normalizer
import java.util.Locale

/**
 * Pure Logik rund um die Suchhistorie.
 *
 * 1:1-Port der iOS-Implementation (`SearchHistoryStore.swift`).
 */
object SearchHistory {
    private val combiningMarks = Regex("\\p{Mn}+")

    /**
     * Setzt `term` an die Spitze, dedupliziert case- und diakritika-insensitiv,
     * kappt das Ergebnis auf `limit` Eintraege.
     *
     * - Leere oder reine Whitespace-Begriffe lassen die Historie unveraendert.
     * - Bei Duplikat gewinnt die Originalschreibweise des neu uebergebenen Terms.
     */
    fun prepend(history: List<String>, term: String, limit: Int): List<String> {
        val trimmed = term.trim()
        if (trimmed.isEmpty()) {
            return history
        }

        val normalized = normalize(trimmed)
        val withoutDuplicate = history.filter { normalize(it) != normalized }
        val combined = listOf(trimmed) + withoutDuplicate
        return if (combined.size > limit) {
            combined.take(limit)
        } else {
            combined
        }
    }

    /**
     * Normalisiert einen Eintrag fuer den Vergleich (lowercase + diakritika entfernt).
     */
    fun normalize(value: String): String = combiningMarks
        .replace(Normalizer.normalize(value, Normalizer.Form.NFD), "")
        .lowercase(Locale.ROOT)
}
