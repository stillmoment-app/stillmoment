//
//  SettingCardsGrid.swift
//  Still Moment
//
//  Presentation Layer - 3+2 layout of setting cards on the timer config screen.
//

import SwiftUI

struct SettingCardsGrid: View {
    let preparation: SettingCardsGridItem
    let attunement: SettingCardsGridItem
    let background: SettingCardsGridItem
    let gong: SettingCardsGridItem
    let interval: SettingCardsGridItem

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                self.cardView(self.preparation)
                self.cardView(self.attunement)
                self.cardView(self.background)
            }
            HStack(spacing: 8) {
                self.cardView(self.gong)
                self.cardView(self.interval)
            }

            Text("settings.card.hint", bundle: .main)
                .font(.system(size: 10.5, weight: .regular, design: .rounded))
                .tracking(1.3)
                .foregroundColor(self.theme.textSecondary.opacity(0.8))
                .textCase(.uppercase)
                .padding(.top, 4)
        }
    }

    private func cardView(_ item: SettingCardsGridItem) -> some View {
        SettingCard(
            label: item.label,
            icon: item.icon,
            value: item.value,
            isOff: item.isOff,
            action: item.action
        )
    }
}

struct SettingCardsGridItem {
    let label: String
    let icon: String
    let value: String
    let isOff: Bool
    let action: () -> Void
}
