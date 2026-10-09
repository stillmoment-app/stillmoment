//
//  OtherLanguageSourcesSection.swift
//  Still Moment
//
//  Presentation Layer - Collapsible sources of another language (Content Guide, shared-137).
//

import SwiftUI

/// Sources of a language other than the user's own: a collapsed row
/// ("Auch auf Englisch · 4 weitere Quellen") that unfolds the source card below it.
///
/// Tapping the row only toggles; it never leaves the Content Guide.
struct OtherLanguageSourcesSection: View {
    // MARK: Internal

    let group: MeditationSourceGroup
    /// Name of the group's language in the user's language, e.g. "Englisch".
    let languageName: String
    @Binding var isExpanded: Bool
    let onTapSource: (MeditationSource) -> Void

    var body: some View {
        VStack(spacing: 12) {
            self.toggleRow
            if self.isExpanded {
                MeditationSourceCard(sources: self.group.sources, onTap: self.onTapSource)
            }
        }
        .padding(.top, 14)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var title: String {
        String(
            format: NSLocalizedString("guided_meditations.guide.otherLanguage.title", comment: ""),
            self.languageName
        )
    }

    private var count: String {
        String.localizedStringWithFormat(
            NSLocalizedString("guided_meditations.guide.otherLanguage.count", comment: ""),
            self.group.sources.count
        )
    }

    /// "Auch auf Englisch, 4 weitere Quellen" — both visible lines, read as one.
    private var accessibilityText: String {
        [self.title, self.count].joined(separator: ", ")
    }

    private var stateDescription: String {
        self.isExpanded
            ? NSLocalizedString("guided_meditations.guide.otherLanguage.expanded", comment: "")
            : NSLocalizedString("guided_meditations.guide.otherLanguage.collapsed", comment: "")
    }

    private var toggleRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(self.title)
                        .textStyle(.body, color: \.textPrimary)
                    Text(self.count)
                        .textStyle(.caption, color: \.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(self.theme.textSecondary)
                    .rotationEffect(.degrees(self.isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(self.theme.cardBackground.opacity(.opacityShadow))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityText)
        .accessibilityValue(self.stateDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("library.guideSheet.language.\(self.group.languageCode)")
    }
}
