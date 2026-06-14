//
//  GongCardBackground.swift
//  Still Moment
//
//  Presentation Layer — shared card surface for the gong selection screen (shared-115).
//
//  Matches `PlaybackRangeCard`: rounded surface filled with `cardBackground`,
//  a 0.5pt `cardBorder` stroke, and (in light mode) the warm lifted shadow.
//  In dark mode the border carries the lift, so no shadow is applied.
//

import SwiftUI

/// Rounds, fills, strokes and (light mode only) lifts a card surface.
struct GongCardBackground: ViewModifier {
    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(self.theme.cardBackground)
                    .modifier(LiftedCardShadow(isDark: self.colorScheme == .dark))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }

    private static let cornerRadius: CGFloat = 22
}
