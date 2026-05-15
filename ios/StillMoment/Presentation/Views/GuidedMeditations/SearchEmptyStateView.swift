//
//  SearchEmptyStateView.swift
//  Still Moment
//
//  Presentation - Empty State bei 0 Treffern (ios-041).
//

import SwiftUI

/// Zeigt den Empty-State, wenn die Eingabe keine Treffer hat.
///
/// Traegt `accessibilityAddTraits(.isStaticText)` + `accessibilityElement(children: .combine)`,
/// damit VoiceOver den Zustand zusammenhaengend ansagt.
struct SearchEmptyStateView: View {
    let query: String

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        VStack(spacing: 0) {
            self.glyph
                .padding(.bottom, 18)
            Text("library.search.empty.title", bundle: .main)
                .themeFont(.screenTitle)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            Text(self.subtitleText)
                .themeFont(.bodySecondary, color: \.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 36)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var subtitleText: String {
        String(format: NSLocalizedString("library.search.empty.message", comment: ""), self.query)
    }

    private var glyph: some View {
        ZStack {
            Circle()
                .fill(self.theme.cardBackground.opacity(0.5))
                .frame(width: 56, height: 56)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(self.theme.textSecondary)
                .accessibilityHidden(true)
        }
    }
}
