//
//  LibraryActionPill.swift
//  Still Moment
//
//  Presentation - Kombinierte Aktion-Pille im Library-Header (ios-051).
//
//  Sitzt rechts im Library-Header neben der Such-Pille. Enthaelt zwei Buttons
//  ("+" fuer Import, "i" fuer Content-Guide), visuell verbunden durch eine
//  1pt-Trennlinie. Im aktiven Such-Zustand wird die Pille vom Header
//  ausgeblendet — ein "Abbrechen"-Button nimmt ihren Platz ein.
//

import SwiftUI

struct LibraryActionPill: View {
    let onAdd: () -> Void
    let onInfo: () -> Void

    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            self.iconButton(
                systemName: "plus",
                accessibilityLabel: "guided_meditations.add",
                accessibilityHint: "accessibility.library.add.hint",
                accessibilityIdentifier: "library.button.add",
                action: self.onAdd
            )

            Rectangle()
                .fill(self.theme.divider)
                .frame(width: 1, height: 18)

            self.iconButton(
                systemName: "info.circle",
                accessibilityLabel: "guided_meditations.guide.info",
                accessibilityHint: nil,
                accessibilityIdentifier: "library.button.guide",
                action: self.onInfo
            )
        }
        .frame(height: 40)
        .background(self.background)
    }

    private func iconButton(
        systemName: String,
        accessibilityLabel: LocalizedStringKey,
        accessibilityHint: LocalizedStringKey?,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(self.theme.textPrimary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .modifier(OptionalAccessibilityHint(hint: accessibilityHint))
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder private var background: some View {
        let capsule = Capsule()
        if self.colorScheme == .dark {
            capsule
                .fill(self.theme.cardBackground)
                .overlay(
                    capsule.strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
                )
        } else {
            capsule
                .fill(self.theme.cardBackground)
                .shadow(
                    color: self.theme.cardShadow,
                    radius: 2,
                    x: 0,
                    y: 1
                )
        }
    }
}

private struct OptionalAccessibilityHint: ViewModifier {
    let hint: LocalizedStringKey?

    func body(content: Content) -> some View {
        if let hint = self.hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
