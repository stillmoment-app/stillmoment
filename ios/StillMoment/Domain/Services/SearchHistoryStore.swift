//
//  SearchHistoryStore.swift
//  Still Moment
//
//  Domain - Persistenz-Protokoll + pure prepend-Logik fuer die Suchhistorie.
//

import Foundation

/// Persistenz fuer die Bibliotheks-Suchhistorie.
///
/// Implementierungen leben in der Infrastructure-Schicht (UserDefaults o.ae.).
protocol SearchHistoryStore {
    func load() -> [String]
    func save(_ history: [String])
}

/// Pure Logik rund um die Suchhistorie.
enum SearchHistory {
    /// Setzt `term` an die Spitze, deduliziert case- und diakritika-insensitiv,
    /// kappt das Ergebnis auf `limit` Eintraege.
    ///
    /// - Leere oder reine Whitespace-Begriffe lassen die Historie unveraendert.
    /// - Bei Duplikat gewinnt die Originalschreibweise des neu uebergebenen Terms.
    static func prepend(history: [String], term: String, limit: Int) -> [String] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return history
        }

        let normalized = self.normalize(trimmed)
        let withoutDuplicate = history.filter { self.normalize($0) != normalized }
        let combined = [trimmed] + withoutDuplicate
        if combined.count > limit {
            return Array(combined.prefix(limit))
        }
        return combined
    }

    /// Normalisiert einen Eintrag fuer den Vergleich (lowercase + diakritika entfernt).
    static func normalize(_ value: String) -> String {
        value
            .folding(options: .diacriticInsensitive, locale: nil)
            .lowercased()
    }
}
