//
//  TrimEdgeChip.swift
//  Still Moment
//
//  Presentation Layer — off-window mark indicator at the track edge (shared-108).
//

import SwiftUI

/// Pill at the track edge standing in for a mark that lies outside the zoom window
/// ("‹ Anfang 0:42" / "Ende 19:05 ›"). Tapping selects the mark and frames it —
/// identical to tapping its readout card.
struct TrimEdgeChip: View {
    // MARK: Internal

    let point: TrimPoint
    let time: TimeInterval
    /// True when the mark lies before the window — the chevron points left.
    let pointsLeading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 4) {
                if self.pointsLeading {
                    self.chevron("chevron.left")
                }
                Text(self.labelText)
                    .textStyle(.caption, monospacedDigits: true)
                    .foregroundColor(self.theme.interactive)
                if !self.pointsLeading {
                    self.chevron("chevron.right")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(self.theme.accentBubbleBackground))
            .overlay(
                Capsule()
                    .strokeBorder(self.theme.interactive.opacity(0.4), lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(self.accessibilityLabelText))
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var labelText: String {
        let key = self.point == .start ? "trim_editor.edgeChip.start" : "trim_editor.edgeChip.end"
        return String(
            format: NSLocalizedString(key, comment: "Edge chip for an off-window mark"),
            EditSheetState.formatTime(self.time)
        )
    }

    private var accessibilityLabelText: String {
        let key = self.point == .start ? "trim_editor.a11y.edgeChip.start" : "trim_editor.a11y.edgeChip.end"
        return String(
            format: NSLocalizedString(key, comment: "Edge chip accessibility label"),
            EditSheetState.formatTime(self.time)
        )
    }

    private func chevron(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(self.theme.interactive)
    }
}
