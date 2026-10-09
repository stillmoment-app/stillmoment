//
//  HowToImportPodcastsView.swift
//  Still Moment
//
//  Presentation Layer - How-to guide for importing a single episode from the
//  Apple Podcasts app via the iOS share sheet (shared-133). Pushed onto the
//  ContentGuideSheet's NavigationStack.
//

import SwiftUI

struct HowToImportPodcastsView: View {
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
                    self.note
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("library.guideSheet.howto.podcasts")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("guided_meditations.guide.howto.eyebrow")
                .textStyle(.micro, color: \.interactive)
                .textCase(.uppercase)
                .tracking(1.6)
                .accessibilityHidden(true)
            Text("guided_meditations.guide.howto.podcasts.title")
                .textStyle(.screenTitle, color: \.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("library.guideSheet.howto.podcasts.title")
        }
        .padding(.bottom, 12)
    }

    private var intro: some View {
        Text("guided_meditations.guide.howto.podcasts.intro")
            .textStyle(.caption, color: \.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 20)
    }

    private var steps: some View {
        VStack(spacing: 0) {
            HowToImportStepCard(
                stepNumber: 1,
                icon: "magnifyingglass",
                titleKey: "guided_meditations.guide.howto.podcasts.step1.title",
                bodyKey: "guided_meditations.guide.howto.podcasts.step1.body"
            )
            HowToImportStepConnector()
            HowToImportStepCard(
                stepNumber: 2,
                icon: "square.and.arrow.up",
                titleKey: "guided_meditations.guide.howto.podcasts.step2.title",
                bodyKey: "guided_meditations.guide.howto.podcasts.step2.body"
            )
            HowToImportStepConnector()
            HowToImportStepCard(
                stepNumber: 3,
                icon: "checkmark.circle",
                titleKey: "guided_meditations.guide.howto.podcasts.step3.title",
                bodyKey: "guided_meditations.guide.howto.podcasts.step3.body"
            )
        }
    }

    /// Quiet hint below the steps: only single episodes can be added.
    /// Read by VoiceOver right after step 3.
    private var note: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(self.theme.textSecondary)
                .accessibilityHidden(true)
            Text("guided_meditations.guide.howto.podcasts.note")
                .textStyle(.caption, color: \.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("library.guideSheet.howto.podcasts.note")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Podcasts Howto") {
    ThemeRootView {
        NavigationStack {
            HowToImportPodcastsView()
        }
    }
}
#endif
