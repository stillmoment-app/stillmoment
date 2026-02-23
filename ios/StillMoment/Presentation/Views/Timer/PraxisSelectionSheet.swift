//
//  PraxisSelectionSheet.swift
//  Still Moment
//
//  Presentation Layer - Bottom Sheet for Praxis selection
//

import SwiftUI

/// Bottom sheet for selecting, creating, and managing Praxis presets.
struct PraxisSelectionSheet: View {
    // MARK: Lifecycle

    init(
        viewModel: PraxisSelectionViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: Internal

    var body: some View {
        NavigationStack {
            ZStack {
                self.theme.backgroundGradient
                    .ignoresSafeArea()

                List {
                    ForEach(self.viewModel.praxes) { praxis in
                        self.praxisRow(for: praxis)
                    }

                    self.createNewPraxisButton
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("praxis.sheet.title", bundle: .main)
                        .themeFont(.inlineNavigationTitle)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("button.done", comment: "")) {
                        self.onDismiss()
                    }
                    .foregroundColor(self.theme.interactive)
                    .accessibilityIdentifier("button.done")
                }
            }
            .navigationDestination(isPresented: self.$showEditor) {
                if let praxis = self.editingPraxis {
                    PraxisEditorView(viewModel: PraxisEditorViewModel(
                        praxis: praxis,
                        onSaved: { [weak viewModel] savedPraxis in
                            viewModel?.load()
                            viewModel?.selectPraxis(savedPraxis)
                            self.onDismiss()
                        },
                        onDeleted: { [weak viewModel] in
                            viewModel?.load()
                            if let active = viewModel?.activePraxis {
                                viewModel?.selectPraxis(active)
                            }
                            self.onDismiss()
                        }
                    ))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(
            NSLocalizedString("praxis.delete.title", comment: ""),
            isPresented: .constant(self.viewModel.praxisToDelete != nil)
        ) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {
                self.viewModel.praxisToDelete = nil
            }
            Button(NSLocalizedString("praxis.delete.confirm", comment: ""), role: .destructive) {
                self.viewModel.confirmDelete()
            }
        } message: {
            if let praxis = self.viewModel.praxisToDelete {
                Text(String(
                    format: NSLocalizedString("praxis.delete.message", comment: ""),
                    praxis.name
                ))
            }
        }
        .alert(
            NSLocalizedString("common.error", comment: ""),
            isPresented: .constant(self.viewModel.errorMessage != nil)
        ) {
            Button(NSLocalizedString("common.ok", comment: "")) {
                self.viewModel.errorMessage = nil
            }
        } message: {
            if let error = self.viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            self.viewModel.load()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisSelectionViewModel
    @State private var editingPraxis: Praxis?
    @State private var showEditor = false

    private let onDismiss: () -> Void
}

// MARK: - Row Views

extension PraxisSelectionSheet {
    private func praxisRow(for praxis: Praxis) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(praxis.name)
                    .themeFont(.listActionLabel)
                Text(praxis.shortDescription)
                    .themeFont(.listSubtitle)
            }

            Spacer()

            if self.viewModel.activePraxisId == praxis.id {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
                    .font(.system(size: 14, weight: .semibold))
                    .accessibilityLabel(NSLocalizedString("accessibility.praxis.active", comment: ""))
            }

            self.overflowMenu(for: praxis)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.selectPraxis(praxis)
            self.onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: NSLocalizedString("accessibility.praxis.row", comment: ""),
            praxis.name
        ))
        .accessibilityIdentifier("praxis.row.\(praxis.id.uuidString)")
    }

    private func overflowMenu(for praxis: Praxis) -> some View {
        Menu {
            Button {
                self.editingPraxis = praxis
                self.showEditor = true
            } label: {
                Label(
                    NSLocalizedString("praxis.edit.label", comment: ""),
                    systemImage: "pencil"
                )
            }
            Button(role: .destructive) {
                self.viewModel.requestDelete(praxis)
            } label: {
                Label(
                    NSLocalizedString("praxis.delete.label", comment: ""),
                    systemImage: "trash"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(self.theme.interactive)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(String(
            format: NSLocalizedString("accessibility.praxis.overflow", comment: ""),
            praxis.name
        ))
        .accessibilityIdentifier("praxis.overflow.\(praxis.id.uuidString)")
    }

    private var createNewPraxisButton: some View {
        Button {
            let newPraxis = self.viewModel.createNewPraxis()
            self.editingPraxis = newPraxis
            self.showEditor = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .accessibilityHidden(true)
                Text("praxis.create.button", bundle: .main)
                    .themeFont(.listActionLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Capsule()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundColor(self.theme.textSecondary.opacity(0.5))
            )
        }
        .foregroundColor(self.theme.textSecondary)
        .accessibilityLabel(NSLocalizedString("accessibility.praxis.create", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.praxis.create.hint", comment: ""))
        .accessibilityIdentifier("praxis.button.create")
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("PraxisSelectionSheet") {
    Text("Timer Screen")
        .sheet(isPresented: .constant(true)) {
            PraxisSelectionSheet(
                viewModel: PraxisSelectionViewModel { _ in }
            ) {}
        }
}
#endif
