//
//  HowToImportStepCard.swift
//  Still Moment
//
//  Presentation Layer - Numbered step card used in HowToImport*View (shared-039b).
//

import SwiftUI

/// Single step row in an import how-to guide.
///
/// Shows a number-badge (left), an SF Symbol icon, a title and a body text.
/// VoiceOver announces the step as „Schritt N von 3, <title>, <body>".
struct HowToImportStepCard: View {
    // MARK: Internal

    let stepNumber: Int
    let icon: String
    let titleKey: String
    let bodyKey: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            self.badge
            self.content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(self.theme.cardBackground.opacity(.opacitySecondary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var badge: some View {
        ZStack {
            Circle()
                .fill(self.theme.accentBubbleBackground)
                .frame(width: 32, height: 32)
            Text("\(self.stepNumber)")
                .themeFont(.bodyPrimary, size: 14, color: \.interactive)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: self.icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(self.theme.textSecondary)
                Text(LocalizedStringKey(self.titleKey))
                    .themeFont(.listTitle)
            }
            Text(LocalizedStringKey(self.bodyKey))
                .themeFont(.bodySecondary, color: \.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accessibilityLabel: String {
        let countFormat = NSLocalizedString(
            "guided_meditations.guide.howto.stepCount",
            comment: ""
        )
        let count = String(format: countFormat, self.stepNumber)
        let title = NSLocalizedString(self.titleKey, comment: "")
        let body = NSLocalizedString(self.bodyKey, comment: "")
        return "\(count), \(title), \(body)"
    }
}

// MARK: - Connector

/// Vertical line drawn between two step cards in a how-to guide.
///
/// Aligned with the badge centre (left padding 14 + badge radius 16 = 30pt).
struct HowToImportStepConnector: View {
    @Environment(\.themeColors)
    private var theme

    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 30)
            Rectangle()
                .fill(self.theme.cardBorder)
                .frame(width: 1, height: 14)
            Spacer()
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Step Card") {
    ThemeRootView {
        VStack(spacing: 0) {
            HowToImportStepCard(
                stepNumber: 1,
                icon: "square.and.arrow.up",
                titleKey: "guided_meditations.guide.howto.browser.step1.title",
                bodyKey: "guided_meditations.guide.howto.browser.step1.body"
            )
            HowToImportStepConnector()
            HowToImportStepCard(
                stepNumber: 2,
                icon: "flame",
                titleKey: "guided_meditations.guide.howto.browser.step2.title",
                bodyKey: "guided_meditations.guide.howto.browser.step2.body"
            )
        }
        .padding()
    }
}
#endif
