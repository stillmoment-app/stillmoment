//
//  CardRowBackground.swift
//  Still Moment
//
//  Presentation Layer - Card row background with visual separation.
//
//  Provides visual elevation for list row cards:
//  - Light mode: soft drop shadow
//  - Dark mode: subtle border (light edge on dark card)
//

import SwiftUI

/// Card row background that provides visual separation from the gradient background.
///
/// Used as `.listRowBackground()` replacement in `.insetGrouped` lists.
/// In light mode, renders a soft shadow. In dark mode, renders a subtle border.
struct CardRowBackground: View {
    let theme: ThemeColors
    let colorScheme: ColorScheme

    var body: some View {
        if self.colorScheme == .dark {
            self.theme.cardBackground
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
                )
        } else {
            self.theme.cardBackground
                .shadow(
                    color: self.theme.textPrimary.opacity(.opacityCardShadow),
                    radius: 8,
                    x: 0,
                    y: 2
                )
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
    ///
    /// Replaces `.listRowBackground(self.theme.cardBackground)` with
    /// a version that adds shadow (light mode) or border (dark mode).
    func cardRowBackground() -> some View {
        modifier(CardRowBackgroundModifier())
    }
}
