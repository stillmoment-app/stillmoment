//
//  SettingCard.swift
//  Still Moment
//
//  Presentation Layer - Single setting card on the timer config screen (shared-083)
//
//  Visible, clearly tappable card with label, icon and current value. Off-state
//  renders as dimmed (opacity 0.45). Theme-tinted background and border.
//

import SwiftUI

struct SettingCard: View {
    let label: String
    let icon: String
    let value: String
    let isOff: Bool
    let identifier: String
    let action: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.action) {
            VStack(spacing: 7) {
                Text(self.label.uppercased())
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .tracking(1.3)
                    .foregroundColor(self.theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: self.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(self.theme.interactive)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                Text(self.value)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(self.theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
        }
        .buttonStyle(SettingCardButtonStyle(theme: self.theme))
        .opacity(self.isOff ? Self.dimmedOpacity : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(self.identifier)
    }

    private static let dimmedOpacity: Double = 0.45
}

/// Press-state for cards: subtle scale + slight background shift.
private struct SettingCardButtonStyle: ButtonStyle {
    let theme: ThemeColors

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.theme.settingCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(self.theme.settingCardBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Setting Card") {
    HStack(spacing: 8) {
        SettingCard(
            label: "Vorbereitung",
            icon: "hourglass",
            value: "10 Sek.",
            isOff: false,
            identifier: "timer.card.preparation"
        ) {}
        SettingCard(
            label: "Einstimmung",
            icon: "sparkles",
            value: "Ohne",
            isOff: true,
            identifier: "timer.card.attunement"
        ) {}
        SettingCard(
            label: "Hintergrund",
            icon: "wind",
            value: "Stille",
            isOff: false,
            identifier: "timer.card.background"
        ) {}
    }
    .padding()
}
#endif
