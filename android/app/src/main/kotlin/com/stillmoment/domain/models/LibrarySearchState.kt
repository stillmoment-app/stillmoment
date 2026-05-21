package com.stillmoment.domain.models

/**
 * Welche Ansicht die Library aktuell rendert.
 *
 * Wird aus `searchQuery`, `isSearchFocused` und der Trefferzahl abgeleitet.
 *
 * - `Idle`: Suchfeld nicht fokussiert, keine Eingabe — bestehende gruppierte Liste.
 * - `History`: Suchfeld fokussiert, keine Eingabe — Suchhistorie sichtbar.
 * - `Results`: Eingabe vorhanden, mindestens ein Treffer.
 * - `Empty`: Eingabe vorhanden, kein Treffer.
 */
sealed class LibrarySearchState {
    data object Idle : LibrarySearchState()

    data object History : LibrarySearchState()

    data object Results : LibrarySearchState()

    data object Empty : LibrarySearchState()
}
