//
//  CardRowBackground.swift
//  Still Moment
//
//  Presentation Layer - Card row background with visual separation.
//
//  Provides visual elevation for list row cards.
//
//  Beide Modi nutzen denselben Doppelschatten-Mechanismus (Contact + Body),
//  jeweils in warmer Erd-/Schwarz-Toenung. Im Dark ist der Lift zusaetzlich
//  durch eine warm-getoente Border verstaerkt — der Card-Hintergrund ist
//  bereits heller als der Mittel-Gradient, der Border zieht die Kante warm.
//

import SwiftUI

/// Card row background that provides visual separation from the gradient background.
///
/// Used as `.listRowBackground()` replacement in `.insetGrouped` lists.
struct CardRowBackground: View {
    let theme: ThemeColors
    let colorScheme: ColorScheme

    var body: some View {
        if self.colorScheme == .dark {
            self.theme.cardBackground
                .modifier(LiftedCardShadow(isDark: true))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
                )
        } else {
            self.theme.cardBackground
                .modifier(LiftedCardShadow(isDark: false))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Lifted Card Shadow

/// Warm double-shadow ViewModifier (Contact + Body).
///
/// Beide Modi nutzen identische Geometrie, die Farben sind ColorScheme-aware
/// und folgen pixelgenau dem Handover (shared-094). Werte sind im Modifier
/// hardcoded statt als Theme-Tokens, weil das Single-Theme-System keinen
/// Mehrwert aus einer zusaetzlichen Indirektion zieht.
struct LiftedCardShadow: ViewModifier {
    let isDark: Bool

    func body(content: Content) -> some View {
        if self.isDark {
            content
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.30), radius: 20, x: 0, y: 8)
        } else {
            let warmShadowColor = Color(
                red: 120 / 255,
                green: 55 / 255,
                blue: 28 / 255
            )
            content
                .shadow(color: warmShadowColor.opacity(0.06), radius: 2, x: 0, y: 1)
                .shadow(color: warmShadowColor.opacity(0.10), radius: 16, x: 0, y: 6)
        }
    }
}

// MARK: - ViewModifier

/// ViewModifier that applies themed card row background based on color scheme.
///
/// Reads `@Environment(\.themeColors)` and `@Environment(\.colorScheme)`,
/// then applies the appropriate visual separation style.
private struct CardRowBackgroundModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

    func body(content: Content) -> some View {
        content.listRowBackground(
            CardRowBackground(theme: self.theme, colorScheme: self.colorScheme)
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply themed card row background with visual separation.
    func cardRowBackground() -> some View {
        modifier(CardRowBackgroundModifier())
    }
}
