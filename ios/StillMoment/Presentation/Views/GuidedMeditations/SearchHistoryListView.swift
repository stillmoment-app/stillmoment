//
//  SearchHistoryListView.swift
//  Still Moment
//
//  Presentation - Liste der zuletzt gesuchten Begriffe (ios-041).
//

import SwiftUI

/// Zeigt die zuletzt gesuchten Begriffe. Wird gerendert, wenn das Suchfeld
/// fokussiert ist UND die Eingabe leer ist.
struct SearchHistoryListView: View {
    let history: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        VStack(spacing: 0) {
            self.header
            if self.history.isEmpty {
                Spacer()
            } else {
                self.entriesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            Text("library.search.history.title", bundle: .main)
                .themeFont(.listSubtitle, color: \.textSecondary)
            Spacer()
            if !self.history.isEmpty {
                Button {
                    self.onClear()
                } label: {
                    Text("library.search.history.clear", bundle: .main)
                        .themeFont(.bodySecondary, color: \.interactive)
                }
                .accessibilityIdentifier("library.search.history.clear")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var entriesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(self.history, id: \.self) { term in
                    self.historyRow(term: term)
                }
            }
        }
    }

    private func historyRow(term: String) -> some View {
        Button {
            self.onSelect(term)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .foregroundColor(self.theme.textSecondary)
                    .frame(width: 20)
                Text(term)
                    .themeFont(.bodyPrimary)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(self.theme.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(String(format: NSLocalizedString("accessibility.library.search.history.entry", comment: ""), term))
        )
        .accessibilityIdentifier("library.search.history.entry.\(term)")
    }
}
