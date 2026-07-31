//
//  LibrarySearchState.swift
//  Still Moment
//
//  Domain - Sichtbarer Zustand der Bibliotheks-Suche (ios-041).
//

import Foundation

/// Welche Ansicht die Library aktuell rendert.
///
/// Wird aus `searchQuery`, `isSearching`, dem Dauer-Filter und der Trefferzahl abgeleitet.
enum LibrarySearchState: Equatable {
    /// Suchfeld nicht fokussiert, keine Eingabe, kein Filter — bestehende gruppierte Liste.
    case idle
    /// Suchfeld fokussiert, keine Eingabe — Suchhistorie sichtbar.
    case history
    /// Keine Eingabe, aber ein Dauer-Filter gesetzt — flache Liste (shared-081).
    case filtered
    /// Eingabe und/oder Filter vorhanden, mindestens ein Treffer.
    case results
    /// Eingabe und/oder Filter vorhanden, kein Treffer.
    case empty
}
