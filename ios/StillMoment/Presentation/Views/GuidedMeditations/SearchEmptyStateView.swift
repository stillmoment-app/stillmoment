//
//  SearchEmptyStateView.swift
//  Still Moment
//
//  Presentation - Empty State bei 0 Treffern (ios-041, Filter-Ursachen shared-081).
//

import SwiftUI

/// Zeigt den Empty-State, wenn Suche und/oder Dauer-Filter nichts uebrig lassen.
///
/// Der Untertitel nennt jede wirkende Ursache — Suchbegriff, Dauer-Stufe oder beide —
/// damit der User sieht, warum eine erwartete Meditation fehlt. Bei gesetztem Filter
/// raeumt ein einzelner Tap Suchtext und Filter gemeinsam ab.
///
/// Traegt `accessibilityAddTraits(.isStaticText)` + `accessibilityElement(children: .combine)`,
/// damit VoiceOver den Zustand zusammenhaengend ansagt.
struct SearchEmptyStateView: View {
    let query: String
    /// Gesetzte Dauer-Stufe, `nil` wenn nur die Suche greift.
    let activeFilter: DurationFilter?
    /// Raeumt Suchtext und Filter gemeinsam ab. Wird nur bei gesetztem Filter angeboten.
    let onReset: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        VStack(spacing: 0) {
            self.message
            if self.activeFilter != nil {
                self.resetButton
                    .padding(.top, 24)
            }
        }
        .padding(.horizontal, 36)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Glyph + Titel + Ursachen-Satz, fuer VoiceOver zu einem Element zusammengefasst.
    private var message: some View {
        VStack(spacing: 0) {
            self.glyph
                .padding(.bottom, 18)
            Text("library.search.empty.title", bundle: .main)
                .textStyle(.screenTitle, color: \.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            Text(self.subtitleText)
                .textStyle(.caption, color: \.textSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    /// Nennt die Ursachen: Suchbegriff, Dauer-Stufe oder beide.
    private var subtitleText: String {
        guard let filter = self.activeFilter else {
            return String(format: NSLocalizedString("library.search.empty.message", comment: ""), self.query)
        }
        guard !self.query.isEmpty else {
            return String(
                format: NSLocalizedString("library.filter.empty.message", comment: ""),
                filter.localizedTitle
            )
        }
        return String(
            format: NSLocalizedString("library.searchFilter.empty.message", comment: ""),
            self.query,
            filter.localizedTitle
        )
    }

    private var resetButton: some View {
        Button(action: self.onReset) {
            Text("library.filter.reset", bundle: .main)
                .textStyle(.caption, color: \.interactive)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(
                    Capsule()
                        .strokeBorder(self.theme.interactive.opacity(0.35), lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("library.filter.reset")
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
