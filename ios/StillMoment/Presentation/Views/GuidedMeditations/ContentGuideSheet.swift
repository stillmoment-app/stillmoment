//
//  ContentGuideSheet.swift
//  Still Moment
//
//  Presentation Layer - Curated, locale-specific list of free meditation sources.
//

import SwiftUI

/// Sheet listing curated, free meditation sources for the current locale.
///
/// Reachable from the empty-state secondary CTA and from the `info.circle`
/// button in the library nav bar. Source content lives in
/// `meditation_sources.json`; taps open the URL in the system browser.
struct ContentGuideSheet: View {
    // MARK: Lifecycle

    init(
        sources: [MeditationSource],
        onOpenURL: @escaping (URL) -> Void = { url in
            UIApplication.shared.open(url)
        },
        onDismiss: @escaping () -> Void
    ) {
        self.sources = sources
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
                    self.sourceList
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

    private let sources: [MeditationSource]
    private let onOpenURL: (URL) -> Void
    private let onDismiss: () -> Void

    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("guided_meditations.guide.title")
                .themeFont(.screenTitle)
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
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var intro: some View {
        Text("guided_meditations.guide.intro")
            .themeFont(.bodySecondary, color: \.textSecondary)
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
        }
        .padding(.bottom, 24)
    }

    private var sourceList: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.sources.enumerated()), id: \.element.id) { index, source in
                SourceRow(
                    source: source,
                    showsTopDivider: index > 0
                ) {
                    self.handleTap(on: source)
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
                .themeFont(.listTitle)
                .multilineTextAlignment(.leading)
            Text(LocalizedStringKey(self.subtitleKey))
                .themeFont(.bodySecondary, color: \.textSecondary)
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

// MARK: - Row

private struct SourceRow: View {
    // MARK: Internal

    let source: MeditationSource
    let showsTopDivider: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    self.titleLine
                    Text(self.source.description)
                        .themeFont(.bodySecondary, color: \.textSecondary)
                        .multilineTextAlignment(.leading)
                    Text(self.source.host)
                        .themeFont(.caption, color: \.textSecondary)
                        .opacity(.opacitySecondary)
                }
                Spacer(minLength: 12)
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(self.theme.interactive)
                    .padding(.top, 2)
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityHint("guided_meditations.guide.openSource")
        .accessibilityAddTraits(.isLink)
        .accessibilityIdentifier("library.guideSheet.row.\(self.source.id)")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var accessibilityLabel: String {
        var parts = [self.source.name]
        if let author = source.author {
            parts.append(author)
        }
        parts.append(self.source.description)
        return parts.joined(separator: ", ")
    }

    @ViewBuilder private var titleLine: some View {
        if let author = self.source.author {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(self.source.name)
                    .themeFont(.listTitle)
                Text("·")
                    .themeFont(.bodySecondary, color: \.textSecondary)
                Text(author)
                    .themeFont(.bodySecondary, color: \.textSecondary)
            }
        } else {
            Text(self.source.name)
                .themeFont(.listTitle)
        }
    }
}

// MARK: - Previews

#if DEBUG
private let previewSources: [MeditationSource] = [
    MeditationSource(
        id: "tara-brach",
        name: "Tara Brach",
        author: nil,
        description: "Guided meditations, RAIN practice. Direct MP3.",
        host: "tarabrach.com",
        // swiftlint:disable:next force_unwrapping
        url: URL(string: "https://www.tarabrach.com/guided-meditations/")!
    ),
    MeditationSource(
        id: "audio-dharma",
        name: "Audio Dharma",
        author: "Gil Fronsdal",
        description: "Vipassana tradition. Direct MP3.",
        host: "audiodharma.org",
        // swiftlint:disable:next force_unwrapping
        url: URL(string: "https://www.audiodharma.org/")!
    )
]

@available(iOS 17.0, *)
#Preview("Guide Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ThemeRootView {
                NavigationStack {
                    ContentGuideSheet(
                        sources: previewSources,
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
