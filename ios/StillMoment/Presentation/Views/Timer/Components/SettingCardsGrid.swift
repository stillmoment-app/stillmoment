//
//  SettingCardsGrid.swift
//  Still Moment
//
//  Presentation Layer - 2+2 layout of setting cards on the timer config screen.
//

import SwiftUI

struct SettingCardsGrid: View {
    let preparation: SettingCardsGridItem
    let background: SettingCardsGridItem
    let gong: SettingCardsGridItem
    let interval: SettingCardsGridItem

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                self.cardView(self.preparation)
                self.cardView(self.background)
            }
            HStack(spacing: 8) {
                self.cardView(self.gong)
                self.cardView(self.interval)
            }
        }
    }

    private func cardView(_ item: SettingCardsGridItem) -> some View {
        SettingCard(
            label: item.label,
            icon: item.icon,
            value: item.value,
            isOff: item.isOff,
            identifier: item.identifier,
            action: item.action
        )
    }
}

struct SettingCardsGridItem {
    let label: String
    let icon: String
    let value: String
    let isOff: Bool
    let identifier: String
    let action: () -> Void
}
