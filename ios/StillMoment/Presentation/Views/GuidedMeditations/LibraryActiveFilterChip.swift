//
//  LibraryActiveFilterChip.swift
//  Still Moment
//
//  Presentation - Gesetzter Dauer-Filter im Suchmodus (shared-081).
//
//  Sobald das Suchfeld benutzt wird, weicht die volle Stufenzeile diesem
//  einzelnen Chip. Er erklaert, warum eine erwartete Meditation in der
//  Trefferliste fehlt — Antippen entfernt den Filter.
//

import SwiftUI

struct LibraryActiveFilterChip: View {
    let filter: DurationFilter
    let onRemove: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.onRemove) {
            HStack(spacing: 6) {
                Text(LocalizedStringKey(self.filter.titleKey), bundle: .main)
                    .textStyle(.caption, color: \.interactive)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(self.theme.interactive)
                    .accessibilityHidden(true)
            }
            .fixedSize()
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(self.chipBackground)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(self.filter.titleKey), bundle: .main))
        .accessibilityHint("accessibility.library.filter.chip.hint")
        .accessibilityIdentifier("library.filter.activeChip")
    }

    private var chipBackground: some View {
        let capsule = Capsule()
        return capsule
            .fill(self.theme.accentBubbleBackground)
            .overlay(capsule.strokeBorder(self.theme.accentBannerBorder, lineWidth: 1))
    }
}
