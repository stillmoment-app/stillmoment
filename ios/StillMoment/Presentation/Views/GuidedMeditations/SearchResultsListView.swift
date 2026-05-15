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
    let onOpenMeditation: (GuidedMeditation) -> Void
    let onStartPreview: (GuidedMeditation) -> Void
    let onStopPreview: () -> Void
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
            .themeFont(.caption, color: \.textSecondary)
            .textCase(nil)
    }

    private func row(for meditation: GuidedMeditation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HighlightedText(text: meditation.effectiveName, query: self.query)
                    .themeFont(.listActionLabel)
                HStack(spacing: 6) {
                    HighlightedText(text: meditation.effectiveTeacher, query: self.query)
                        .themeFont(.listSubtitle, color: \.textSecondary)
                    Text(verbatim: "·")
                        .themeFont(.listSubtitle, color: \.textSecondary)
                    Text(meditation.formattedDuration)
                        .themeFont(.listSubtitle, color: \.textSecondary)
                }
            }
            Spacer()
            self.playButton(for: meditation)
        }
        .padding(.vertical, 4)
        .cardRowBackground()
        .accessibilityIdentifier("library.search.row.\(meditation.id.uuidString)")
    }

    private func playButton(for meditation: GuidedMeditation) -> some View {
        let isThisPreviewing = self.previewingMeditationId == meditation.id
        return Image(systemName: isThisPreviewing ? "stop.circle.fill" : "play.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(self.theme.interactive)
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
