//
//  MeditationSourceCard.swift
//  Still Moment
//
//  Presentation Layer - Card listing curated meditation sources (Content Guide, shared-137).
//

import SwiftUI

/// Card with the curated sources of one language, separated by thin dividers.
///
/// Each row shows name, offer (if it has its own name), description and address.
/// Tapping a row hands its source to `onTap`.
struct MeditationSourceCard: View {
    // MARK: Internal

    let sources: [MeditationSource]
    let onTap: (MeditationSource) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.sources.enumerated()), id: \.element.id) { index, source in
                MeditationSourceRow(
                    source: source,
                    showsTopDivider: index > 0
                ) {
                    self.onTap(source)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(self.theme.cardBackground.opacity(.opacitySecondary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
}

// MARK: - Row

private struct MeditationSourceRow: View {
    // MARK: Internal

    let source: MeditationSource
    let showsTopDivider: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Text(self.source.name)
                    .textStyle(.body, color: \.textPrimary)
                if let offer = self.source.offer {
                    Text(offer)
                        .textStyle(.caption, color: \.textPrimary)
                        .opacity(.opacityTertiary)
                }
                Text(self.source.description)
                    .textStyle(.caption, color: \.textSecondary)
                    .padding(.top, 4)
                self.address
                    .padding(.top, 6)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if self.showsTopDivider {
                Rectangle()
                    .fill(self.theme.cardBorder.opacity(.opacitySecondary))
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityHint("guided_meditations.guide.openSource")
        .accessibilityAddTraits(.isLink)
        .accessibilityIdentifier("library.guideSheet.row.\(self.source.id)")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    /// Name, offer, description, address — the order in which the row is shown.
    private var accessibilityLabel: String {
        [self.source.name, self.source.offer, self.source.description, self.source.host]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private var address: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(self.source.host)
                .textStyle(.micro, color: \.interactive)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(self.theme.interactive)
        }
    }
}
