//
//  TrimReadoutCards.swift
//  Still Moment
//
//  Presentation Layer — Anfang/Ende readout cards for the trim editor (shared-107).
//

import SwiftUI

/// The two "Anfang"/"Ende" cards below the waveform. Tapping a card selects the
/// corresponding point as active; the active card is highlighted. Exposed as buttons
/// with the `.isSelected` trait for the active one.
struct TrimReadoutCards: View {
    // MARK: Internal

    let start: TimeInterval
    let end: TimeInterval
    let activePoint: TrimPoint
    let onSelect: (TrimPoint) -> Void

    var body: some View {
        HStack(spacing: 10) {
            self.card(
                point: .start,
                label: "trim_editor.card.start",
                value: self.start
            )
            self.card(
                point: .end,
                label: "trim_editor.card.end",
                value: self.end
            )
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private func card(point: TrimPoint, label: LocalizedStringKey, value: TimeInterval) -> some View {
        let isActive = self.activePoint == point
        let labelKey = point == .start ? "trim_editor.card.start" : "trim_editor.card.end"
        return Button {
            self.onSelect(point)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .textStyle(.eyebrow, color: \.textSecondary)
                Text(EditSheetState.formatTime(value))
                    .textStyle(.title, monospacedDigits: true)
                    .foregroundColor(isActive ? self.theme.interactive : self.theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? self.theme.accentBubbleBackground : self.theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isActive ? self.theme.interactive.opacity(0.4) : self.theme.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(NSLocalizedString(labelKey, comment: "Trim point card label")))
        .accessibilityValue(Text(EditSheetState.formatTime(value)))
        .accessibilityHint(Text("trim_editor.a11y.cardHint"))
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
