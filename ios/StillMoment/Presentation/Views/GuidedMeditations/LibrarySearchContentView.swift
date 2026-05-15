//
//  LibrarySearchContentView.swift
//  Still Moment
//
//  Presentation - Bridge zwischen `.searchable` und den 4 Suchzustaenden (ios-041).
//
//  Diese View liest `@Environment(\.isSearching)` und reicht den Wert an das
//  ViewModel weiter — das geht nur in einer View, die ein Child der
//  `.searchable`-Hierarchie ist. Der Body wechselt zwischen idle/history/
//  results/empty basierend auf dem abgeleiteten `searchState`.
//

import SwiftUI

struct LibrarySearchContentView<IdleContent: View>: View {
    @ObservedObject var viewModel: GuidedMeditationsListViewModel
    let onOpenMeditation: (GuidedMeditation) -> Void
    let onStartPreview: (GuidedMeditation) -> Void
    let onStopPreview: () -> Void
    let onEditMeditation: (GuidedMeditation) -> Void
    let onDeleteMeditation: (GuidedMeditation) -> Void
    @ViewBuilder let idleContent: () -> IdleContent

    @Environment(\.isSearching)
    private var isSearching

    var body: some View {
        self.stateContent
            .onChange(of: self.isSearching) { newValue in
                self.viewModel.isSearching = newValue
            }
    }

    @ViewBuilder private var stateContent: some View {
        switch self.viewModel.searchState {
        case .idle:
            self.idleContent()
        case .history:
            SearchHistoryListView(
                history: self.viewModel.searchHistory,
                onSelect: { term in
                    self.viewModel.selectHistoryEntry(term)
                },
                onClear: {
                    self.viewModel.clearHistory()
                }
            )
        case .results:
            SearchResultsListView(
                meditations: self.viewModel.searchResults,
                query: self.viewModel.searchQuery,
                previewingMeditationId: self.viewModel.previewingMeditationId,
                onOpenMeditation: { meditation in
                    self.viewModel.recordSearchCommittedByOpening()
                    self.onOpenMeditation(meditation)
                },
                onStartPreview: self.onStartPreview,
                onStopPreview: self.onStopPreview,
                onEditMeditation: self.onEditMeditation,
                onDeleteMeditation: self.onDeleteMeditation
            )
        case .empty:
            SearchEmptyStateView(query: self.viewModel.searchQuery)
        }
    }
}
