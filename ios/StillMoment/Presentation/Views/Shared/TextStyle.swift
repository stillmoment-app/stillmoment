//
//  TextStyle.swift
//  Still Moment
//
//  Presentation Layer — Typography 2.1 (Quelle: handoffs/Typografie 2.1 - Plan.html)
//
//  10 Tokens, jedes an eine Dynamic-Type-Basis gebunden. Custom-Fonts skalieren ueber
//  `Font.custom(_:size:relativeTo:)` mit den System-Einstellungen mit.
//  Ausnahme: `.display` ist container-relativ — siehe `DisplayNumeral`.
//

import SwiftUI

/// Die zehn Tokens des Typografie-Systems.
///
/// Reihenfolge folgt der Plan-Tabelle (Display → Eyebrow). Jede Rolle bindet eine
/// Schriftfamilie + ein Gewicht + eine Dynamic-Type-Basis. Italic ist eine eigene
/// Rolle (`.bodyItalic`), kein orthogonaler Modifier.
enum TextStyle: CaseIterable {
    /// Container-relativ — Timer-Countdown, Dial-Value. Siehe `DisplayNumeral`.
    case display
    /// Newsreader Light, .largeTitle-Basis — Player-Track-Title, Cover-Headlines.
    case title
    /// Newsreader Light, .title-Basis — Screen-Header (Large-Title, Inline-NavBar).
    case screenTitle
    /// Newsreader Light, .title3-Basis — List-Section-Title, Dialog-Title.
    case section
    /// Geist Regular, .body-Basis — Standardtext, List-Row-Title, Settings-Label.
    case body
    /// Geist Medium, .body-Basis — primaere CTAs, Tab-Bar-aktiv, List-Action-Label.
    case bodyEmphasis
    /// Newsreader Italic, .body-Basis — Lehrer-Name, Eigennamen, Akzent (`<em>`).
    case bodyItalic
    /// Geist Regular, .subheadline-Basis — List-Subtitle, Settings-Description.
    case caption
    /// Geist Regular, .caption2-Basis — Timestamps, Units, Card-Labels.
    case micro
    /// Geist Regular UPPER tracked, .caption2-Basis — Tracked-Caps-Labels, Section-Eyebrows.
    case eyebrow

    // MARK: - Dynamic-Type-Basis

    /// iOS-TextStyle, an die der Token via `UIFontMetrics` gebunden ist. Bestimmt
    /// die Skalierungsachse fuer Dynamic Type.
    var textStyle: Font.TextStyle {
        switch self {
        case .display,
             .title:
            .largeTitle
        case .screenTitle:
            .title
        case .section:
            .title3
        case .body,
             .bodyEmphasis,
             .bodyItalic:
            .body
        case .caption:
            .subheadline
        case .micro,
             .eyebrow:
            .caption2
        }
    }

    // MARK: - Base Size

    /// Basis-Groesse bei Dynamic-Type-Einstellung "Large" (Default, AX aus).
    /// `Font.custom(_:size:relativeTo:)` skaliert davon ausgehend.
    /// Bei `.display` wird dieser Wert ueberschrieben — Container berechnet selbst.
    var baseSize: CGFloat {
        switch self {
        case .display: 88
        case .title: 30
        case .screenTitle: 26
        case .section: 20
        case .body,
             .bodyEmphasis,
             .bodyItalic: 17
        case .caption: 14
        case .micro,
             .eyebrow: 11
        }
    }

    // MARK: - Font-PostScript-Name (Default — ohne Bold-Text-Bump)

    /// PostScript-Name aus dem App-Bundle. Newsreader heisst `Newsreader16pt-*`
    /// (16pt-Optical-Size-Variante), Geist heisst schlicht `Geist-*`.
    /// Bei Bold-Text-Setting wird dieser Name ueber `effectiveFontName(legibility:)`
    /// auf einen schwereren Cut gemappt.
    var fontName: String {
        switch self {
        case .display,
             .title,
             .screenTitle,
             .section:
            "Newsreader16pt-Light"
        case .body,
             .caption,
             .micro,
             .eyebrow:
            "Geist-Regular"
        case .bodyEmphasis:
            "Geist-Medium"
        case .bodyItalic:
            "Newsreader16pt-Italic"
        }
    }

    // MARK: - Tracking

    /// Letter-Spacing in pt @ Basis-Groesse. Default 0 — nur Rollen mit bewusstem
    /// Tracking-Bedarf weichen ab.
    /// `.eyebrow`: 2.4 pt = ~0.22em @ 11pt (tracked caps).
    /// `.title` / `.screenTitle`: -0.4 (leicht enger fuer grosse Display-Buchstaben).
    var tracking: CGFloat {
        switch self {
        case .title,
             .screenTitle: -0.4
        case .eyebrow: 2.4
        default: 0
        }
    }

    // MARK: - Uppercase

    /// Nur `.eyebrow` ist tracked caps. Wird ueber `.textCase(.uppercase)` gesetzt.
    var uppercase: Bool {
        self == .eyebrow
    }

    // MARK: - Bold Text Setting (Accessibility)

    /// Wenn der User „Fett gedruckter Text" aktiviert, verschieben wir den Cut
    /// um einen Schritt schwerer — analog zu Apples System-Font-Verhalten.
    ///
    /// Mapping:
    /// - Geist Regular → Geist Medium
    /// - Geist Medium → Geist SemiBold (neu in Typografie 2.1)
    /// - Newsreader Light → Newsreader Regular
    /// - Italic bleibt Italic (kein Bold-Italic-Cut im Bundle).
    func effectiveFontName(legibility: LegibilityWeight?) -> String {
        guard legibility == .bold else {
            return self.fontName
        }
        switch self {
        case .body,
             .caption,
             .micro,
             .eyebrow:
            return "Geist-Medium"
        case .bodyEmphasis:
            return "Geist-SemiBold"
        case .display,
             .title,
             .screenTitle,
             .section:
            return "Newsreader16pt-Regular"
        case .bodyItalic:
            return "Newsreader16pt-Italic"
        }
    }
}
