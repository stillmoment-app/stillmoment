//
//  LibraryHeaderView.swift
//  Still Moment
//
//  Presentation - Fixierter Library-Header mit Such-Pille (ios-051).
//
//  Sitzt via `.safeAreaInset(edge: .top)` ueber dem Library-Inhalt und bleibt
//  beim Scrollen sichtbar. Links eine Such-Pille (TextField + Lupe + Clear-X),
//  rechts entweder die Aktion-Pille (+/i, im Idle) oder ein "Abbrechen"-Button
//  (im aktiven Such-Fokus). Der `@FocusState` propagiert direkt an
//  `viewModel.isSearching` und ersetzt die alte `.searchable()`-Bridge.
//

import SwiftUI

struct LibraryHeaderView: View {
    @ObservedObject var viewModel: GuidedMeditationsListViewModel
    let onAdd: () -> Void
    let onInfo: () -> Void
    let onSubmit: () -> Void

    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme
    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            self.searchPill

            if self.searchFocused {
                self.cancelButton
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                LibraryActionPill(onAdd: self.onAdd, onInfo: self.onInfo)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.2), value: self.searchFocused)
        .onChange(of: self.searchFocused) { newValue in
            self.viewModel.isSearching = newValue
        }
        .onChange(of: self.viewModel.isSearching) { newValue in
            if !newValue, self.searchFocused {
                self.searchFocused = false
            }
        }
    }

    private var searchPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(self.searchFocused ? self.theme.interactive : self.theme.textSecondary)
                .accessibilityHidden(true)

            TextField(
                "",
                text: self.$viewModel.searchQuery,
                prompt: Text("library.search.prompt", bundle: .main)
                    .foregroundColor(self.theme.textSecondary)
            )
            .textStyle(.body, color: \.textPrimary)
            .focused(self.$searchFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit(self.onSubmit)
            .accessibilityLabel("accessibility.library.search.field")
            .accessibilityIdentifier("library.search.field")

            if !self.viewModel.searchQuery.isEmpty {
                Button {
                    self.viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(self.theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .accessibilityLabel("accessibility.library.search.clear")
                .accessibilityIdentifier("library.search.clear")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(self.searchPillBackground)
        .contentShape(Capsule())
        .onTapGesture {
            self.searchFocused = true
        }
        .animation(.easeInOut(duration: 0.18), value: self.viewModel.searchQuery.isEmpty)
    }

    @ViewBuilder private var searchPillBackground: some View {
        let capsule = Capsule()
        if self.colorScheme == .dark {
            capsule
                .fill(self.theme.cardBackground)
                .overlay(
                    capsule.strokeBorder(
                        self.searchFocused ? self.theme.interactive.opacity(0.35) : self.theme.cardBorder,
                        lineWidth: self.searchFocused ? 1 : 0.5
                    )
                )
        } else {
            capsule
                .fill(self.theme.cardBackground)
                .overlay(
                    capsule.strokeBorder(
                        self.theme.interactive.opacity(self.searchFocused ? 0.25 : 0),
                        lineWidth: 1
                    )
                )
                .shadow(
                    color: self.theme.cardShadow,
                    radius: 2,
                    x: 0,
                    y: 1
                )
        }
    }

    private var cancelButton: some View {
        Button {
            self.viewModel.resetSearch()
            self.searchFocused = false
        } label: {
            Text("common.cancel", bundle: .main)
                .textStyle(.body, color: \.interactive)
                .frame(minHeight: 40)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("accessibility.library.search.cancel")
        .accessibilityIdentifier("library.search.cancel")
    }
}
