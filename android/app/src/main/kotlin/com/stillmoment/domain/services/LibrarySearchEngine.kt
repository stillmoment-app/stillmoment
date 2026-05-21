package com.stillmoment.domain.services

import com.stillmoment.domain.models.GuidedMeditation
import java.text.Normalizer
import java.util.Locale

/**
 * Pure Such-Funktionen fuer die Volltext-Suche in der Library.
 *
 * - Multi-Token-Split (Whitespace), UND-Verknuepfung.
 * - Case- und diakritika-insensitiver Substring-Match.
 * - Ranking nach 4 Buckets:
 *   1. Wortanfang im Titel
 *   2. Wortanfang im Lehrer
 *   3. Substring im Titel
 *   4. Substring im Lehrer
 * - Bei mehreren Tokens gewinnt der beste Bucket (best-match-wins).
 * - Tiebreaker: neueres `dateAdded` zuerst.
 *
 * 1:1-Port der iOS-Implementation (`LibrarySearchEngine.swift`).
 */
object LibrarySearchEngine {
    private val combiningMarks = Regex("\\p{Mn}+")

    /**
     * Zerlegt die Eingabe in Tokens (Whitespace-getrennt).
     */
    fun tokens(query: String): List<String> = query
        .split(Regex("\\s+"))
        .filter { it.isNotEmpty() }

    /**
     * Filtert und sortiert Meditationen nach Relevanz.
     *
     * - Such-Targets sind `effectiveName` und `effectiveTeacher` — die UI-sichtbaren
     *   Texte (Custom-Overrides ueberschreiben den ID3-Tag, siehe shared-094).
     */
    fun search(meditations: List<GuidedMeditation>, query: String): List<GuidedMeditation> {
        val queryTokens = tokens(query)
        if (queryTokens.isEmpty()) {
            return emptyList()
        }

        val ranked = meditations.mapNotNull { meditation ->
            val tokenBuckets = mutableListOf<MatchBucket>()
            for (token in queryTokens) {
                val bucket = bestBucket(token, meditation) ?: return@mapNotNull null
                tokenBuckets.add(bucket)
            }
            // best-match-wins: bester (kleinster) Bucket ueber alle Tokens
            val bestForMeditation = tokenBuckets.min()
            meditation to bestForMeditation
        }

        return ranked
            .sortedWith(
                compareBy<Pair<GuidedMeditation, MatchBucket>> { it.second.ordinal }
                    .thenByDescending { it.first.dateAdded }
            )
            .map { it.first }
    }

    /**
     * Liefert alle Vorkommen jedes Tokens im Text als `IntRange`s.
     *
     * - Wird zum Highlighten in der UI verwendet.
     * - Case- und diakritika-insensitiv.
     * - Ueberlappende Ranges werden zusammengefasst.
     * - Ranges beziehen sich auf Indizes im **Original-Text** (NFC), nicht auf den
     *   gefolteten Vergleichs-String — das Folding ist ein Codepoint-Strip und kann
     *   die Index-Mapping verschieben, deshalb beide Seiten Codepoint-weise foltern.
     */
    fun highlightRanges(text: String, query: String): List<IntRange> {
        val queryTokens = tokens(query)
        if (queryTokens.isEmpty()) {
            return emptyList()
        }

        val collected = mutableListOf<IntRange>()
        for (token in queryTokens) {
            collected.addAll(rangesOf(token, text))
        }
        return mergeOverlapping(collected)
    }

    // MARK: - Private

    /**
     * Bucket des besten Treffers fuer ein einzelnes Token in einer Meditation.
     *
     * Priorisiert in Reihenfolge: Wortanfang-Titel, Wortanfang-Lehrer,
     * Substring-Titel, Substring-Lehrer.
     */
    private fun bestBucket(token: String, meditation: GuidedMeditation): MatchBucket? {
        val title = meditation.effectiveName
        val teacher = meditation.effectiveTeacher

        return when {
            hasWordStartMatch(token, title) -> MatchBucket.WordStartInTitle
            hasWordStartMatch(token, teacher) -> MatchBucket.WordStartInTeacher
            hasSubstring(token, title) -> MatchBucket.SubstringInTitle
            hasSubstring(token, teacher) -> MatchBucket.SubstringInTeacher
            else -> null
        }
    }

    private fun hasSubstring(token: String, text: String): Boolean = rangesOf(token, text).isNotEmpty()

    private fun hasWordStartMatch(token: String, text: String): Boolean {
        val ranges = rangesOf(token, text)
        for (range in ranges) {
            if (isWordStart(range.first, text)) {
                return true
            }
        }
        return false
    }

    private fun isWordStart(index: Int, text: String): Boolean {
        if (index == 0) {
            return true
        }
        if (index < 1 || index > text.length) {
            return false
        }
        val previous = text[index - 1]
        return !previous.isLetterOrDigit()
    }

    /**
     * Findet alle Vorkommen von `substring` in `text` als Index-Ranges (`first..last`)
     * relativ zum Original-Text.
     *
     * Folding (Diakritika strippen + lowercase) wird **codepoint-erhaltend** angewendet:
     * `Normalizer.NFD` + `\p{Mn}+`-Strip aendert die Laenge nicht zwingend, aber
     * Code-Point-IDs bleiben erhalten — kombinierende Akzente werden zu separaten
     * Code-Points, die wir loeschen. Dadurch kann ein gefoldeter String _kuerzer_
     * sein als der Original-String, was die Mapping-Indizes verschiebt. Wir vergleichen
     * deshalb Char-fuer-Char ueber `foldedAt(...)` mit kumuliertem Index.
     *
     * Diese Variante ist robust und korrekt — bei den max. ~500 Library-Eintraegen
     * mit kurzen Titeln deutlich unter 1 ms.
     */
    private fun rangesOf(substring: String, text: String): List<IntRange> {
        if (substring.isEmpty() || text.isEmpty()) {
            return emptyList()
        }
        val needle = fold(substring)
        if (needle.isEmpty()) {
            return emptyList()
        }
        val foldedText = fold(text)
        // Wenn das Folding die String-Laenge erhaelt (kein Diakritikum-Strip), koennen
        // wir 1:1-Indizes nutzen. Andernfalls fallen wir auf eine Mapping-Tabelle zurueck.
        return if (foldedText.length == text.length) {
            findFoldedRanges(foldedText, needle)
        } else {
            findFoldedRangesWithMapping(text, foldedText, needle)
        }
    }

    private fun findFoldedRanges(foldedText: String, needle: String): List<IntRange> {
        val result = mutableListOf<IntRange>()
        var fromIndex = 0
        while (true) {
            val idx = foldedText.indexOf(needle, fromIndex)
            if (idx < 0) {
                break
            }
            result.add(idx..(idx + needle.length - 1))
            fromIndex = idx + needle.length
        }
        return result
    }

    /**
     * Suche im Folded-String, mappe Treffer auf Original-Char-Indizes zurueck.
     *
     * Mapping `foldedIndex -> originalIndex` wird einmal aufgebaut. Pro Original-Char
     * speichern wir den `folded`-Start-Index; daraus laesst sich `original.start` und
     * `original.endExclusive` ableiten.
     */
    private fun findFoldedRangesWithMapping(original: String, foldedText: String, needle: String): List<IntRange> {
        val originalToFoldedStart = IntArray(original.length + 1)
        var cursor = 0
        for (i in original.indices) {
            originalToFoldedStart[i] = cursor
            val foldedChar = fold(original[i].toString())
            cursor += foldedChar.length
        }
        originalToFoldedStart[original.length] = cursor

        // Reverse-Lookup: zu jedem `foldedIndex` der Original-Index, an dem ein Char beginnt.
        val foldedToOriginal = IntArray(cursor + 1)
        var lastOriginal = 0
        for (i in 0..original.length) {
            val foldedPos = if (i < originalToFoldedStart.size) originalToFoldedStart[i] else cursor
            while (lastOriginal <= foldedPos && lastOriginal < foldedToOriginal.size) {
                foldedToOriginal[lastOriginal] = i
                lastOriginal++
            }
        }
        while (lastOriginal < foldedToOriginal.size) {
            foldedToOriginal[lastOriginal] = original.length
            lastOriginal++
        }

        val result = mutableListOf<IntRange>()
        var fromIndex = 0
        while (true) {
            val idx = foldedText.indexOf(needle, fromIndex)
            if (idx < 0) {
                break
            }
            val foldedEnd = idx + needle.length
            val originalStart = foldedToOriginal[idx.coerceAtMost(foldedToOriginal.size - 1)]
            val originalEnd = foldedToOriginal[foldedEnd.coerceAtMost(foldedToOriginal.size - 1)]
            if (originalEnd > originalStart) {
                result.add(originalStart..(originalEnd - 1))
            }
            fromIndex = foldedEnd
        }
        return result
    }

    /**
     * Codepoint-Normalisierung: NFD + Combining-Marks strippen + lowercase mit `Locale.ROOT`.
     *
     * `Locale.ROOT` vermeidet die Tuerkisch-Falle (`I` → `ı`).
     */
    private fun fold(value: String): String = combiningMarks
        .replace(Normalizer.normalize(value, Normalizer.Form.NFD), "")
        .lowercase(Locale.ROOT)

    /**
     * Fasst ueberlappende oder beruehrende Ranges zusammen.
     */
    private fun mergeOverlapping(ranges: List<IntRange>): List<IntRange> {
        if (ranges.isEmpty()) {
            return emptyList()
        }
        val sorted = ranges.sortedBy { it.first }
        val merged = mutableListOf(sorted.first())
        for (range in sorted.drop(1)) {
            val last = merged.last()
            if (range.first <= last.last + 1) {
                val upper = if (range.last > last.last) range.last else last.last
                merged[merged.size - 1] = last.first..upper
            } else {
                merged.add(range)
            }
        }
        return merged
    }

    /**
     * Internes Ranking-Enum. `ordinal` definiert die Sortierreihenfolge.
     *
     * Keine `sealed class` — wir brauchen nur die Sortierung, kein Polymorphismus.
     */
    private enum class MatchBucket {
        WordStartInTitle,
        WordStartInTeacher,
        SubstringInTitle,
        SubstringInTeacher
    }
}
