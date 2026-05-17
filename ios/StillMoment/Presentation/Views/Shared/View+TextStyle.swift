//
//  View+TextStyle.swift
//  Still Moment
//
//  Presentation Layer — Modifier-Bruecke fuer Typografie 2.1.
//
//  Setzt Font (inkl. Dynamic-Type-Bindung), Tracking und Casing fuer einen Token.
//  Farbe ist optional ueber das `ThemeColors`-Environment — Plan-Philosophie
//  "Hierarchie via Farbe, nicht via Token". Wer keinen Farb-Override braucht,
//  uebergibt nil und setzt die Farbe via `.foregroundColor`/`.foregroundStyle`
//  separat.
//

import SwiftUI

extension View {
    /// Wendet einen Typografie-Token auf einen Text/View an.
    ///
    /// - Parameter style: Der Token aus der Plan-Tabelle (`.body`, `.caption`, …).
    /// - Parameter monospacedDigits: Aktiviert tabular figures — z.B. fuer Restzeit-
    ///   Labels, damit die Ziffern-Breite beim Herunterzaehlen nicht springt.
    /// - Parameter color: Optionaler Theme-Farbschluessel. Default: keine Farbe wird
    ///   gesetzt (die View setzt sie via `.foregroundColor` separat). Plan-Regel:
    ///   sekundaerer Text ist *derselbe* Token mit *anderer* Farbe.
    func textStyle(
        _ style: TextStyle,
        monospacedDigits: Bool = false,
        color: KeyPath<ThemeColors, Color>? = nil
    ) -> some View {
        modifier(TextStyleModifier(style: style, monospacedDigits: monospacedDigits, color: color))
    }
}

/// Liest das `LegibilityWeight`-Environment (Bold-Text-Setting), baut den passenden
/// Custom-Font ueber `Font.custom(_:size:relativeTo:)` (skaliert mit Dynamic Type)
/// und setzt Tracking und Uppercase entsprechend dem Token.
private struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    let monospacedDigits: Bool
    let color: KeyPath<ThemeColors, Color>?

    @Environment(\.legibilityWeight)
    private var legibility

    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        let font = self.resolvedFont
        content
            .font(self.monospacedDigits ? font.monospacedDigit() : font)
            .tracking(self.style.tracking)
            .textCase(self.style.uppercase ? .uppercase : nil)
            .foregroundColor(self.color.map { self.theme[keyPath: $0] })
    }

    private var resolvedFont: Font {
        Font.custom(
            self.style.effectiveFontName(legibility: self.legibility),
            size: self.style.baseSize,
            relativeTo: self.style.textStyle
        )
    }
}
