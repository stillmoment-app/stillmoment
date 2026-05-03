//
//  HowToImportBrowserView.swift
//  Still Moment
//
//  Presentation Layer - How-to guide for importing audio via the iOS share sheet
//  (browser → Share → Still Moment). Pushed onto the ContentGuideSheet's NavigationStack.
//

import SwiftUI

struct HowToImportBrowserView: View {
    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    self.header
                    self.intro
                    self.steps
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("library.guideSheet.howto.browser")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("guided_meditations.guide.howto.eyebrow")
                .themeFont(.caption, color: \.interactive)
                .textCase(.uppercase)
                .tracking(1.6)
                .accessibilityHidden(true)
            Text("guided_meditations.guide.howto.browser.title")
                .themeFont(.screenTitle)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("library.guideSheet.howto.browser.title")
        }
        .padding(.bottom, 12)
    }

    private var intro: some View {
        Text("guided_meditations.guide.howto.browser.intro")
            .themeFont(.bodySecondary, color: \.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 20)
    }

    private var steps: some View {
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
            HowToImportStepConnector()
            HowToImportStepCard(
                stepNumber: 3,
                icon: "checkmark.circle",
                titleKey: "guided_meditations.guide.howto.browser.step3.title",
                bodyKey: "guided_meditations.guide.howto.browser.step3.body"
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Browser Howto") {
    ThemeRootView {
        NavigationStack {
            HowToImportBrowserView()
        }
    }
}
#endif
