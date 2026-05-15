//
//  LibrarySearchState.swift
//  Still Moment
//
//  Domain - Sichtbarer Zustand der Bibliotheks-Suche (ios-041).
//

import Foundation

/// Welche Ansicht die Library aktuell rendert.
///
/// Wird aus `searchQuery`, `isSearching` und der Trefferzahl abgeleitet.
enum LibrarySearchState: Equatable {
    /// Suchfeld nicht fokussiert, keine Eingabe — bestehende gruppierte Liste.
    case idle
    /// Suchfeld fokussiert, keine Eingabe — Suchhistorie sichtbar.
    case history
    /// Eingabe vorhanden, mindestens ein Treffer.
    case results
    /// Eingabe vorhanden, kein Treffer.
    case empty
}
