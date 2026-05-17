//
//  LibrarySearchContentView.swift
//  Still Moment
//
//  Presentation - Rendert die 4 Suchzustaende (ios-041, refaktoriert ios-051).
//
//  Liest ausschliesslich `viewModel.searchState` und rendert den passenden
//  State. Das `isSearching`-Flag wird seit ios-051 vom Header via `@FocusState`
//  direkt am ViewModel gesetzt — kein `@Environment(\.isSearching)` mehr noetig.
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

    var body: some View {
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
