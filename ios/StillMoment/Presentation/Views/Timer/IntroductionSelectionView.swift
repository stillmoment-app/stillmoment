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
/// for the current device language with name and duration. Includes a
/// "My Attunements" section for user-imported custom audio files.
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

                self.myAttunementsSection
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
        .sheet(isPresented: self.$showImportPicker) {
            DocumentPicker { url in
                self.viewModel.importCustomAudio(from: url, type: .attunement)
            }
        }
        .alert(
            Text("custom.audio.delete.confirm.title", bundle: .main),
            isPresented: self.$showDeleteConfirmation,
            presenting: self.fileToDelete
        ) { file in
            Button(
                NSLocalizedString("custom.audio.delete.confirm.button", comment: ""),
                role: .destructive
            ) {
                self.viewModel.deleteCustomAudio(file)
            }
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
        } message: { file in
            let count = self.viewModel.usageCount(for: file)
            let warning: String = if count == 1 {
                NSLocalizedString("custom.audio.delete.warning.single", comment: "")
            } else if count > 1 {
                String(format: NSLocalizedString("custom.audio.delete.warning.multiple", comment: ""), count)
            } else {
                NSLocalizedString("custom.audio.delete.confirm.message", comment: "")
            }
            Text(warning)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel
    @State private var showImportPicker = false
    @State private var fileToDelete: CustomAudioFile?
    @State private var showDeleteConfirmation = false

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

    private var myAttunementsSection: some View {
        Section {
            Button {
                self.showImportPicker = true
            } label: {
                Label(
                    NSLocalizedString("custom.audio.import.button", comment: ""),
                    systemImage: "plus.circle"
                )
                .themeFont(.settingsLabel)
            }
            .cardRowBackground()
            .accessibilityLabel(
                NSLocalizedString("custom.audio.accessibility.importButton.attunement", comment: "")
            )

            if self.viewModel.customAttunements.isEmpty {
                Text("custom.audio.empty.attunements", bundle: .main)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
                    .cardRowBackground()
            } else {
                ForEach(self.viewModel.customAttunements) { file in
                    self.customAttunementRow(for: file)
                }
            }
        } header: {
            Text("custom.audio.section.myAttunements", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    private func customAttunementRow(for file: CustomAudioFile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .themeFont(.settingsLabel)
                Text(file.formattedDuration)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
            }
            Spacer()
            if self.viewModel.introductionId == file.id.uuidString {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
            Button {
                self.fileToDelete = file
                self.showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(self.theme.textSecondary)
            }
            .accessibilityLabel(
                String(
                    format: NSLocalizedString("custom.audio.accessibility.delete", comment: ""),
                    file.name
                )
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.introductionId = file.id.uuidString
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.introduction.custom.\(file.id.uuidString)")
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
