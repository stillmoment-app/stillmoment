//
//  LibraryDurationFilterRow.swift
//  Still Moment
//
//  Presentation - Horizontale Stufenzeile des Dauer-Filters (shared-081).
//
//  Sitzt im Library-Header unter der Such-Pille und zeigt alle fuenf Stufen als
//  Einzelauswahl. Unbelegte Stufen bleiben sichtbar, aber blass und nicht
//  antippbar — so aendert die Zeile ihre Breite nie.
//

import SwiftUI

struct LibraryDurationFilterRow: View {
    let selected: DurationFilter
    let availableSteps: Set<DurationFilter>
    let onSelect: (DurationFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DurationFilter.allCases, id: \.self) { step in
                    DurationFilterChip(
                        step: step,
                        isSelected: step == self.selected,
                        isAvailable: self.availableSteps.contains(step)
                    ) {
                        self.onSelect(step)
                    }
                }
            }
            .padding(.horizontal, 22)
        }
        .accessibilityIdentifier("library.filter.row")
    }
}

// MARK: - Einzelne Stufe

/// Eine Dauer-Stufe als Capsule. 32 pt sichtbar, 44 pt tappbar — analog zur Such-Pille.
private struct DurationFilterChip: View {
    let step: DurationFilter
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        if self.isAvailable {
            self.button
                .accessibilityAddTraits(self.isSelected ? [.isSelected] : [])
        } else {
            self.button
                .opacity(.opacitySecondary)
                .disabled(true)
                .accessibilityValue(Text("accessibility.library.filter.unavailable", bundle: .main))
        }
    }

    private var button: some View {
        Button(action: self.onTap) {
            Text(LocalizedStringKey(self.step.titleKey), bundle: .main)
                .textStyle(.caption, color: self.textColor)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(self.chipBackground)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("library.filter.step.\(self.step.rawValue)")
    }

    private var textColor: KeyPath<ThemeColors, Color> {
        self.isSelected ? \.interactive : \.textSecondary
    }

    private var chipBackground: some View {
        let capsule = Capsule()
        return capsule
            .fill(self.isSelected ? self.theme.accentBubbleBackground : self.theme.cardBackground)
            .overlay(
                capsule.strokeBorder(
                    self.isSelected ? self.theme.accentBannerBorder : self.theme.cardBorder,
                    lineWidth: self.isSelected ? 1 : 0.5
                )
            )
    }
}
