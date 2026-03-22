//
//  AttunementSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Attunement selection for Praxis editor
//

import SwiftUI

/// Selection list for choosing an optional attunement audio.
///
/// Shows "No Attunement" as first option, then all available attunements
/// for the current device language with name and duration. Includes a
/// "My Attunements" section for user-imported custom audio files.
struct AttunementSelectionView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisEditorViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                List {
                    self.attunementToggleRow

                    if self.viewModel.attunementEnabled {
                        ForEach(self.viewModel.availableAttunements) { attunement in
                            self.attunementRow(for: attunement)
                        }

                        self.myAttunementsSection
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if self.viewModel.attunementEnabled {
                    self.importButton
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("praxis.editor.attunement.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
        }
        .onDisappear {
            self.viewModel.stopAllPreviews()
        }
        .onAppear {
            // Show rename alert for freshly imported custom audio
            if let pending = self.fileOpenHandler.pendingCustomAudioImport,
               pending.type == .attunement {
                self.fileToRename = pending.file
                self.renameText = pending.file.name
                self.showRenameAlert = true
                self.fileOpenHandler.pendingCustomAudioImport = nil
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
        .alert(
            NSLocalizedString("custom.audio.rename.title", comment: ""),
            isPresented: self.$showRenameAlert,
            presenting: self.fileToRename
        ) { file in
            TextField(
                NSLocalizedString("custom.audio.rename.placeholder", comment: ""),
                text: self.$renameText
            )
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("common.save", comment: "")) {
                self.viewModel.renameCustomAudio(file, newName: self.renameText)
            }
        } message: { _ in
            Text("custom.audio.rename.message", bundle: .main)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @ObservedObject private var viewModel: PraxisEditorViewModel
    @State private var showImportPicker = false
    @State private var fileToDelete: CustomAudioFile?
    @State private var showDeleteConfirmation = false
    @State private var fileToRename: CustomAudioFile?
    @State private var renameText: String = ""
    @State private var showRenameAlert = false

    private var attunementToggleRow: some View {
        Toggle(isOn: Binding(
            get: { self.viewModel.attunementEnabled },
            set: { self.viewModel.setAttunementEnabled($0) }
        )) {
            Text("praxis.editor.attunement.row", bundle: .main)
                .themeFont(.settingsLabel)
        }
        .themedToggle()
        .cardRowBackground()
        .accessibilityHint(NSLocalizedString("accessibility.attunement.toggle.hint", comment: ""))
        .accessibilityIdentifier("praxis.attunement.toggle")
    }

    private func attunementRow(for attunement: Attunement) -> some View {
        let isSelected = self.viewModel.attunementId == attunement.id
        return HStack {
            Image(systemName: isSelected ? "waveform.circle.fill" : "waveform.circle")
                .foregroundColor(isSelected ? self.theme.interactive : self.theme.textSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(attunement.name)
                    .themeFont(.settingsLabel)
                Text(attunement.formattedDuration)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.attunementId = attunement.id
            self.viewModel.playAttunementPreview(attunementId: attunement.id)
        }
        .cardRowBackground()
        .accessibilityElement(children: .combine)
        .accessibilityHint(NSLocalizedString("accessibility.sound.select.hint", comment: ""))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("praxis.attunement.\(attunement.id)")
    }

    private var importButton: some View {
        ImportAudioButton(
            accessibilityLabel: NSLocalizedString(
                "custom.audio.accessibility.importButton.attunement",
                comment: ""
            )
        ) {
            self.showImportPicker = true
        }
    }

    private var myAttunementsSection: some View {
        Section {
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
        let isSelected = self.viewModel.attunementId == file.id.uuidString
        return HStack {
            HStack {
                Image(systemName: isSelected ? "waveform.circle.fill" : "waveform.circle")
                    .foregroundColor(isSelected ? self.theme.interactive : self.theme.textSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .themeFont(.settingsLabel)
                    Text(file.formattedDuration)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                self.viewModel.attunementId = file.id.uuidString
                self.viewModel.playAttunementPreview(attunementId: file.id.uuidString)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint(NSLocalizedString("accessibility.sound.select.hint", comment: ""))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            self.overflowMenu(for: file)
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.attunement.custom.\(file.id.uuidString)")
    }

    private func overflowMenu(for file: CustomAudioFile) -> some View {
        Menu {
            Button {
                self.fileToRename = file
                self.renameText = file.name
                self.showRenameAlert = true
            } label: {
                Label("guided_meditations.edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                self.fileToDelete = file
                self.showDeleteConfirmation = true
            } label: {
                Label("custom.audio.delete.confirm.button", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(self.theme.interactive)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("accessibility.library.overflow")
        .accessibilityHint("accessibility.library.overflow.hint")
        .accessibilityIdentifier("praxis.attunement.overflow.\(file.id.uuidString)")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Attunement Selection") {
    NavigationStack {
        AttunementSelectionView(viewModel: PraxisEditorViewModel(praxis: .default) { _ in })
    }
}
#endif
