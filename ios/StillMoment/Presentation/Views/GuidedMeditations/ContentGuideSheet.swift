//
//  ContentGuideSheet.swift
//  Still Moment
//
//  Presentation Layer - Curated list of free meditation sources, grouped by language.
//

import SwiftUI

/// Sheet listing curated, free meditation sources.
///
/// Reachable from the empty-state secondary CTA and from the `info.circle`
/// button in the library nav bar. Source content lives in
/// `meditation_sources.json`; taps open the URL outside the app.
/// The sources of the user's own language (first group) are shown open; every
/// other language follows as a collapsed row (shared-137).
struct ContentGuideSheet: View {
    // MARK: Lifecycle

    init(
        groups: [MeditationSourceGroup],
        languageName: @escaping (String) -> String,
        onOpenURL: @escaping (URL) -> Void = { url in
            UIApplication.shared.open(url)
        },
        onDismiss: @escaping () -> Void
    ) {
        self.groups = groups
        self.languageName = languageName
        self.onOpenURL = onOpenURL
        self.onDismiss = onDismiss
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    self.titleRow
                    self.intro
                    self.importBanners
                    self.sourceGroups
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
        .accessibilityIdentifier("library.guideSheet")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    /// Language codes whose collapsed row the user has opened. Every opening of the
    /// sheet starts collapsed; nothing is stored.
    @State private var expandedLanguageCodes: Set<String> = []

    private let groups: [MeditationSourceGroup]
    private let languageName: (String) -> String
    private let onOpenURL: (URL) -> Void
    private let onDismiss: () -> Void

    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("guided_meditations.guide.title")
                .textStyle(.screenTitle, color: \.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: self.onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(self.theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(self.theme.cardBackground.opacity(.opacitySecondary))
                    )
            }
            .accessibilityLabel("guided_meditations.guide.close")
            .accessibilityIdentifier("library.guideSheet.close")
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var intro: some View {
        Text("guided_meditations.guide.intro")
            .textStyle(.caption, color: \.textSecondary)
            .padding(.bottom, 24)
    }

    private var importBanners: some View {
        VStack(spacing: 10) {
            NavigationLink {
                HowToImportBrowserView()
            } label: {
                ImportBannerCard(
                    icon: "safari",
                    titleKey: "guided_meditations.guide.banner.browser.title",
                    subtitleKey: "guided_meditations.guide.banner.browser.subtitle"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("library.guideSheet.banner.browser")

            NavigationLink {
                HowToImportFilesView()
            } label: {
                ImportBannerCard(
                    icon: "folder",
                    titleKey: "guided_meditations.guide.banner.files.title",
                    subtitleKey: "guided_meditations.guide.banner.files.subtitle"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("library.guideSheet.banner.files")

            NavigationLink {
                HowToImportPodcastsView()
            } label: {
                ImportBannerCard(
                    icon: "antenna.radiowaves.left.and.right",
                    titleKey: "guided_meditations.guide.banner.podcasts.title",
                    subtitleKey: "guided_meditations.guide.banner.podcasts.subtitle"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("library.guideSheet.banner.podcasts")
        }
        .padding(.bottom, 24)
    }

    private var sourceGroups: some View {
        VStack(spacing: 0) {
            if let ownGroup = self.groups.first {
                MeditationSourceCard(sources: ownGroup.sources, onTap: self.handleTap)
            }
            ForEach(self.groups.dropFirst(), id: \.languageCode) { group in
                OtherLanguageSourcesSection(
                    group: group,
                    languageName: self.languageName(group.languageCode),
                    isExpanded: self.expansionBinding(for: group.languageCode),
                    onTapSource: self.handleTap
                )
            }
        }
    }

    private func expansionBinding(for languageCode: String) -> Binding<Bool> {
        Binding(
            get: { self.expandedLanguageCodes.contains(languageCode) },
            set: { isExpanded in
                if isExpanded {
                    self.expandedLanguageCodes.insert(languageCode)
                } else {
                    self.expandedLanguageCodes.remove(languageCode)
                }
            }
        )
    }

    private func handleTap(on source: MeditationSource) {
        self.onOpenURL(source.url)
        self.onDismiss()
    }
}

// MARK: - Banner Card

private struct ImportBannerCard: View {
    // MARK: Internal

    let icon: String
    let titleKey: String
    let subtitleKey: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            self.iconBubble
            self.text
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.theme.textSecondary)
                .opacity(.opacitySecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(self.theme.accentBannerBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(self.theme.accentBannerBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(self.theme.accentBubbleBackground)
                .frame(width: 36, height: 36)
            Image(systemName: self.icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(self.theme.interactive)
        }
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(self.titleKey))
                .textStyle(.body, color: \.textPrimary)
                .multilineTextAlignment(.leading)
            Text(LocalizedStringKey(self.subtitleKey))
                .textStyle(.caption, color: \.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accessibilityLabel: String {
        let title = NSLocalizedString(self.titleKey, comment: "")
        let subtitle = NSLocalizedString(self.subtitleKey, comment: "")
        return "\(title), \(subtitle)"
    }
}

// MARK: - Previews

#if DEBUG
private let previewGroups: [MeditationSourceGroup] = [
    MeditationSourceGroup(languageCode: "de", sources: [
        MeditationSource(
            id: "gein",
            name: "Melissa Gein",
            offer: "Podcast \u{201E}Einfach meditieren\u{201C}",
            description: "Großes Archiv mit kurzen und langen Übungen.",
            host: "podcasts.apple.com",
            url: URL(string: "https://podcasts.apple.com/")!
        ),
        MeditationSource(
            id: "braehler",
            name: "Christine Brähler",
            offer: nil,
            description: "Selbstmitgefühl mit Tiefe: MSC, Herzmeditationen.",
            host: "christinebraehler.com",
            url: URL(string: "https://www.christinebraehler.com/")!
        )
    ]),
    MeditationSourceGroup(languageCode: "en", sources: [
        MeditationSource(
            id: "tara-brach",
            name: "Tara Brach",
            offer: nil,
            description: "Guided meditations, RAIN practice.",
            host: "tarabrach.com",
            url: URL(string: "https://www.tarabrach.com/guided-meditations/")!
        )
    ])
]

@available(iOS 17.0, *)
#Preview("Guide Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ThemeRootView {
                NavigationStack {
                    ContentGuideSheet(
                        groups: previewGroups,
                        languageName: { _ in "Englisch" },
                        onOpenURL: { _ in },
                        onDismiss: {}
                    )
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
}
#endif
