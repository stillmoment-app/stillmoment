package com.stillmoment.domain.models

/**
 * Welche Ansicht die Library aktuell rendert.
 *
 * Wird aus `searchQuery`, `isSearchFocused`, dem Dauer-Filter und der Trefferzahl abgeleitet.
 *
 * - `Idle`: Suchfeld nicht fokussiert, keine Eingabe, kein Filter — gruppierte Liste.
 * - `History`: Suchfeld fokussiert, keine Eingabe — Suchhistorie sichtbar.
 * - `Filtered`: Keine Eingabe, aber ein Dauer-Filter gesetzt — flache Liste (shared-081).
 * - `Results`: Eingabe und/oder Filter vorhanden, mindestens ein Treffer.
 * - `Empty`: Eingabe und/oder Filter vorhanden, kein Treffer.
 */
sealed class LibrarySearchState {
    data object Idle : LibrarySearchState()

    data object History : LibrarySearchState()

    data object Filtered : LibrarySearchState()

    data object Results : LibrarySearchState()

    data object Empty : LibrarySearchState()
}
