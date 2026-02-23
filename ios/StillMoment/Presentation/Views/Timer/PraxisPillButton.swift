//
//  PraxisPillButton.swift
//  Still Moment
//
//  Presentation Layer - Pill button for Praxis selection
//

import SwiftUI

/// Pill-shaped button showing the active Praxis name on the Timer Screen.
/// Tapping opens the Praxis selection sheet.
struct PraxisPillButton: View {
    let praxisName: String
    let action: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 6) {
                Text(String(
                    format: NSLocalizedString("praxis.pill.label", comment: ""),
                    self.praxisName
                ))
                .themeFont(.caption)
                .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(self.theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(self.theme.accentBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        self.theme.textSecondary.opacity(0.2),
                        lineWidth: 0.5
                    )
            )
        }
        .frame(minHeight: 44)
        .accessibilityLabel(String(
            format: NSLocalizedString("accessibility.praxis.pill", comment: ""),
            self.praxisName
        ))
        .accessibilityHint(NSLocalizedString("accessibility.praxis.pill.hint", comment: ""))
        .accessibilityIdentifier("timer.button.praxisPill")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("PraxisPillButton") {
    PraxisPillButton(praxisName: "Standard") {}
        .padding()
}
#endif
