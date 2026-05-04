//
//  IdleSettingsList.swift
//  Still Moment
//
//  Presentation Layer - Flache Settings-Liste auf dem Timer-Idle-Screen (shared-089).
//
//  Ersetzt das vorherige Karten-Grid (shared-083). Eine Zeile pro Setting:
//  Label links, akzentuierter Wert rechts mit dezentem Chevron, durchgehende
//  Trennlinien zwischen den Zeilen, Top-Trennlinie als oberer Abschluss, kein
//  Bottom-Strich. Inaktive Zeilen werden auf Zeilen-Ebene gedaempft (Opazitaet).
//

import SwiftUI

struct IdleSettingsList: View {
    let preparation: IdleSettingsListItem
    let gong: IdleSettingsListItem
    let interval: IdleSettingsListItem
    let background: IdleSettingsListItem

    let isCompactHeight: Bool

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        VStack(spacing: 0) {
            self.divider
            self.row(self.preparation)
            self.divider
            self.row(self.gong)
            self.divider
            self.row(self.interval)
            self.divider
            self.row(self.background)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(self.theme.settingsDivider)
            .frame(height: 0.5)
    }

    private func row(_ item: IdleSettingsListItem) -> some View {
        IdleSettingsListRow(item: item, isCompactHeight: self.isCompactHeight)
    }
}

struct IdleSettingsListItem {
    let label: String
    let value: String
    let isOff: Bool
    let identifier: String
    let accessibilityLabel: String
    let action: () -> Void
}

private struct IdleSettingsListRow: View {
    let item: IdleSettingsListItem
    let isCompactHeight: Bool

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.item.action) {
            HStack(spacing: 12) {
                Text(self.item.label)
                    .themeFont(.bodyPrimary, size: self.labelSize)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(self.item.value)
                    .font(.system(size: self.valueSize, weight: .regular, design: .rounded))
                    .foregroundColor(self.theme.settingsValueAccent)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(self.theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, self.verticalPadding)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(self.item.isOff ? Self.dimmedOpacity : 1.0)
        .animation(.easeInOut(duration: 0.2), value: self.item.isOff)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(self.item.accessibilityLabel))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(self.item.identifier)
    }

    private var labelSize: CGFloat {
        self.isCompactHeight ? 15 : 17
    }

    private var valueSize: CGFloat {
        self.isCompactHeight ? 14 : 15
    }

    private var verticalPadding: CGFloat {
        self.isCompactHeight ? 11 : 14
    }

    private static let dimmedOpacity: Double = 0.45
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Idle Settings List") {
    IdleSettingsList(
        preparation: IdleSettingsListItem(
            label: "Vorbereitung",
            value: "10 Sek.",
            isOff: false,
            identifier: "timer.row.preparation",
            accessibilityLabel: "Vorbereitung, 10 Sekunden, doppelt tippen zum Aendern"
        ) {},
        gong: IdleSettingsListItem(
            label: "Gong",
            value: "Tibetan",
            isOff: false,
            identifier: "timer.row.gong",
            accessibilityLabel: "Gong, Tibetan, doppelt tippen zum Aendern"
        ) {},
        interval: IdleSettingsListItem(
            label: "Intervall",
            value: "Aus",
            isOff: true,
            identifier: "timer.row.interval",
            accessibilityLabel: "Intervall, Aus, doppelt tippen zum Aendern"
        ) {},
        background: IdleSettingsListItem(
            label: "Hintergrund",
            value: "Stille",
            isOff: true,
            identifier: "timer.row.background",
            accessibilityLabel: "Hintergrund, Stille, doppelt tippen zum Aendern"
        ) {},
        isCompactHeight: false
    )
    .padding(.horizontal, 24)
}
#endif
