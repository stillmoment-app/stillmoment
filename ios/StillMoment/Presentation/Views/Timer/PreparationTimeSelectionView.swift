//
//  PreparationTimeSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Preparation time selection (shared-083)
//
//  Pushed detail view that lists "Off" and the six supported seconds values.
//  Tapping a row writes through PraxisEditorViewModel; auto-save persists.
//

import SwiftUI

/// Detail view for picking the preparation time. The first row is "Off",
/// followed by 5/10/15/20/30/45 second options. Selection is live — there
/// is no explicit save step.
struct PreparationTimeSelectionView: View {
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
                Section {
                    self.row(label: NSLocalizedString("common.off", comment: ""), seconds: nil)
                    ForEach(Self.supportedSeconds, id: \.self) { seconds in
                        self.row(label: self.label(for: seconds), seconds: seconds)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("settings.preparationTime.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    private static let supportedSeconds: [Int] = [5, 10, 15, 20, 30, 45]

    private func label(for seconds: Int) -> String {
        NSLocalizedString("settings.preparationTime.\(seconds)s", comment: "")
    }

    private func row(label: String, seconds: Int?) -> some View {
        let isSelected = self.viewModel.isPreparationTimeSelected(seconds: seconds)
        return HStack {
            Text(label)
                .themeFont(.settingsLabel)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.selectPreparationTime(seconds: seconds)
        }
        .cardRowBackground()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(
            seconds.map { "praxis.preparation.\($0)s" } ?? "praxis.preparation.off"
        )
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Preparation Time Selection") {
    NavigationStack {
        PreparationTimeSelectionView(
            viewModel: PraxisEditorViewModel(praxis: .default) { _ in }
        )
    }
}
#endif
