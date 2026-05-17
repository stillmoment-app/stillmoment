//
//  SearchResultsListView.swift
//  Still Moment
//
//  Presentation - Flache Trefferliste mit Match-Highlight (ios-041).
//

import SwiftUI

/// Zeigt die flachen Treffer einer Bibliotheks-Suche.
///
/// Pro Zeile: Titel + Lehrer/Dauer-Untertitel + Play-Button. Match-Highlight
/// in beiden Texten. Swipe-Actions identisch zur normalen Liste.
struct SearchResultsListView: View {
    let meditations: [GuidedMeditation]
    let query: String
    let previewingMeditationId: UUID?
    let previewCurrentTime: TimeInterval
    let previewDuration: TimeInterval
    let onOpenMeditation: (GuidedMeditation) -> Void
    let onStartPreview: (GuidedMeditation) -> Void
    let onStopPreview: () -> Void
    let onSeekPreview: (TimeInterval) -> Void
    let onEditMeditation: (GuidedMeditation) -> Void
    let onDeleteMeditation: (GuidedMeditation) -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        List {
            Section {
                ForEach(self.meditations) { meditation in
                    self.row(for: meditation)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                self.onDeleteMeditation(meditation)
                            } label: {
                                Label("guided_meditations.delete.confirm", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                self.onEditMeditation(meditation)
                            } label: {
                                Label("guided_meditations.edit", systemImage: "pencil")
                            }
                            .tint(self.theme.interactive)
                        }
                }
            } header: {
                self.countHeader
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }

    private var countHeader: some View {
        Text(String(format: NSLocalizedString("library.search.results.count", comment: ""), self.meditations.count))
            .textStyle(.micro, color: \.textSecondary)
            .textCase(nil)
    }

    private func row(for meditation: GuidedMeditation) -> some View {
        let isThisPreviewing = self.previewingMeditationId == meditation.id

        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedText(text: meditation.name, query: self.query)
                        .textStyle(.bodyEmphasis, color: \.textPrimary)
                    HStack(spacing: 6) {
                        HighlightedText(text: meditation.teacher, query: self.query)
                            .textStyle(.caption, color: \.textSecondary)
                        Text(verbatim: "·")
                            .textStyle(.caption, color: \.textSecondary)
                        Text(meditation.formattedDuration)
                            .textStyle(.caption, color: \.textSecondary)
                    }
                }
                Spacer()
                self.playButton(for: meditation)
            }

            if isThisPreviewing {
                MeditationPreviewProgressRow(
                    currentTime: self.previewCurrentTime,
                    duration: self.previewDuration,
                    onSeek: self.onSeekPreview
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .cardRowBackground()
        .animation(.easeInOut(duration: 0.25), value: isThisPreviewing)
        .accessibilityIdentifier("library.search.row.\(meditation.id.uuidString)")
    }

    private func playButton(for meditation: GuidedMeditation) -> some View {
        let isThisPreviewing = self.previewingMeditationId == meditation.id
        return PlayButtonCircle(isPlaying: isThisPreviewing)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                if isThisPreviewing {
                    self.onStopPreview()
                } else {
                    self.onStopPreview()
                    self.onOpenMeditation(meditation)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self.onStartPreview(meditation)
            }
            .accessibilityLabel(isThisPreviewing ? "accessibility.library.stop" : "accessibility.library.preview")
            .accessibilityIdentifier("library.search.button.preview.\(meditation.id.uuidString)")
    }
}
