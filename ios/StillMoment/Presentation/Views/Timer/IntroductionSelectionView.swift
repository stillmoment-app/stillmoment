//
//  IntroductionSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Introduction selection for Praxis editor
//

import SwiftUI

/// Selection list for choosing an optional introduction audio.
///
/// Shows "No Introduction" as first option, then all available introductions
/// for the current device language with name and duration.
struct IntroductionSelectionView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisEditorViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            List {
                self.noneRow

                ForEach(self.viewModel.availableIntroductions) { intro in
                    self.introductionRow(for: intro)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("praxis.editor.introduction.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    private var noneRow: some View {
        HStack {
            Text("praxis.editor.introduction.none", bundle: .main)
                .themeFont(.settingsLabel)
            Spacer()
            if self.viewModel.introductionId == nil {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.introductionId = nil
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.introduction.none")
    }

    private func introductionRow(for intro: Introduction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(intro.name)
                    .themeFont(.settingsLabel)
                Text(intro.formattedDuration)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
            }
            Spacer()
            if self.viewModel.introductionId == intro.id {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.introductionId = intro.id
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.introduction.\(intro.id)")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Introduction Selection") {
    NavigationStack {
        IntroductionSelectionView(viewModel: PraxisEditorViewModel(
            praxis: .default,
            onSaved: { _ in },
            onDeleted: {}
        ))
    }
}
#endif
