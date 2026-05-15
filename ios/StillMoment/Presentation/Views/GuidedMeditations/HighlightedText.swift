//
//  HighlightedText.swift
//  Still Moment
//
//  Presentation - Text mit Match-Highlight fuer die Library-Suche (ios-041).
//

import SwiftUI

/// Rendert `text` und faerbt alle Vorkommen der Suchbegriffe aus `query` in der Akzentfarbe ein.
///
/// - Mehrere Vorkommen werden alle hervorgehoben (nicht nur das erste).
/// - Case- und diakritika-insensitiv (delegiert an `LibrarySearchEngine`).
/// - Foreground = theme.interactive, Weight = semibold. Kein Hintergrund-Tint —
///   der Akzent + die Strichstaerke tragen den Kontrast (auf warmem Card-Background
///   verschwimmt ein zusaetzlicher Tint).
struct HighlightedText: View {
    let text: String
    let query: String

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Text(self.attributed)
    }

    private var attributed: AttributedString {
        var result = AttributedString(self.text)
        let ranges = LibrarySearchEngine.highlightRanges(in: self.text, query: self.query)
        for range in ranges {
            if let attrRange = Range(range, in: result) {
                result[attrRange].foregroundColor = self.theme.interactive
                result[attrRange].font = .body.weight(.semibold)
            }
        }
        return result
    }
}
