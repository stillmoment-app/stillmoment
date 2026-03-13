//
//  GuidedMeditationsListView.swift
//  Still Moment
//
//  Presentation Layer - Guided Meditations List View
//

import SwiftUI
import UniformTypeIdentifiers

/// View displaying the guided meditations library
///
/// Features:
/// - List of meditations grouped by teacher
/// - Import via DocumentPicker
/// - Swipe to delete
/// - Navigation to player
/// - Edit metadata
struct GuidedMeditationsListView: View {
    // MARK: Lifecycle

    init(
        navigationPath: Binding<NavigationPath> = .constant(NavigationPath()),
        viewModel: GuidedMeditationsListViewModel? = nil,
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        settingsRepository: GuidedSettingsRepository = GuidedMeditationSettingsRepository()
    ) {
        _navigationPath = navigationPath
        self.meditationService = meditationService
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: GuidedMeditationsListViewModel(
                meditationService: meditationService
            ))
        }
        self.settingsRepository = settingsRepository
        _settings = State(initialValue: settingsRepository.load())
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            // Warm gradient background (consistent with Timer tab)
            self.theme.backgroundGradient
                .ignoresSafeArea()

            if self.viewModel.meditations.isEmpty {
                self.emptyStateView
            } else {
                self.meditationsList
            }

            if self.viewModel.isMigrating {
                self.migrationOverlay
            } else if self.viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(self.theme.textPrimary.opacity(.opacityOverlay))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("guided_meditations.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.viewModel.showDocumentPicker()
                } label: {
                    Image(systemName: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .foregroundColor(self.theme.textSecondary)
                .accessibilityLabel("guided_meditations.add")
                .accessibilityHint("accessibility.library.add.hint")
                .accessibilityIdentifier("library.button.add")
            }
        }
        .sheet(isPresented: self.$viewModel.showingDocumentPicker) {
            DocumentPicker { url in
                Task {
                    await self.viewModel.importMeditation(from: url)
                }
            }
        }
        .sheet(isPresented: self.$viewModel.showingEditSheet) {
            ThemeRootView {
                if let meditation = viewModel.meditationToEdit {
                    GuidedMeditationEditSheet(
                        meditation: meditation,
                        availableTeachers: self.viewModel.uniqueTeachers,
                        onSave: { updated in
                            self.viewModel.updateMeditation(updated)
                            self.viewModel.showingEditSheet = false
                        },
                        onCancel: {
                            self.viewModel.showingEditSheet = false
                        }
                    )
                }
            }
        }
        .navigationDestination(for: GuidedMeditation.self) { meditation in
            GuidedMeditationPlayerView(
                meditation: meditation,
                preparationTimeSeconds: self.settings.preparationTimeSeconds,
                meditationService: self.meditationService
            )
        }
        .alert(
            NSLocalizedString("common.error", comment: ""),
            isPresented: .constant(self.viewModel.errorMessage != nil)
        ) {
            Button(NSLocalizedString("common.ok", comment: "")) {
                self.viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert(
            NSLocalizedString("guided_meditations.delete.title", comment: ""),
            isPresented: .constant(self.meditationToDelete != nil)
        ) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {
                self.meditationToDelete = nil
            }
            Button(NSLocalizedString("guided_meditations.delete.confirm", comment: ""), role: .destructive) {
                if let meditation = meditationToDelete {
                    self.viewModel.deleteMeditation(meditation)
                }
                self.meditationToDelete = nil
            }
        } message: {
            if let meditation = meditationToDelete {
                Text(
                    String(
                        format: NSLocalizedString("guided_meditations.delete.message", comment: ""),
                        meditation.effectiveName
                    )
                )
            }
        }
        .onAppear {
            self.viewModel.loadMeditations()
            self.settings = self.settingsRepository.load()
        }
        .onChange(of: self.fileOpenHandler.importedMeditation) { newMeditation in
            guard let meditation = newMeditation else {
                return
            }
            // Reload library to include the newly imported file
            self.viewModel.loadMeditations()
            // Open edit sheet for the imported meditation
            self.viewModel.showEditSheet(for: meditation)
            // Consume the event
            self.fileOpenHandler.importedMeditation = nil
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @StateObject private var viewModel: GuidedMeditationsListViewModel
    @State private var meditationToDelete: GuidedMeditation?
    @State private var settings: GuidedMeditationSettings
    @Binding private var navigationPath: NavigationPath
    @State private var isPressing = false
    @State private var longPressActive = false
    @State private var longPressWork: DispatchWorkItem?

    private let meditationService: GuidedMeditationServiceProtocol
    private let settingsRepository: GuidedSettingsRepository

    // MARK: - Subviews

    private var migrationOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("guided_meditations.migration.title")
                .themeFont(.listTitle)
            Text("guided_meditations.migration.message")
                .themeFont(.listSubtitle)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(self.theme.cardBackground)
                .shadow(radius: 8)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(self.theme.textPrimary.opacity(.opacityOverlay))
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("guided_meditations.empty.title")
                .themeFont(.listSectionTitle)

            Text("guided_meditations.empty.message")
                .themeFont(.listBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                self.viewModel.showDocumentPicker()
            } label: {
                Label("guided_meditations.import", systemImage: "plus.circle.fill")
            }
            .warmPrimaryButton()
            .accessibilityHint("accessibility.library.import.hint")
            .accessibilityIdentifier("library.button.import.emptyState")
        }
        .padding()
    }

    private var meditationsList: some View {
        List {
            ForEach(self.viewModel.meditationsByTeacher(), id: \.teacher) { section in
                Section {
                    ForEach(section.meditations) { meditation in
                        self.meditationRow(for: meditation)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            self.meditationToDelete = section.meditations[index]
                        }
                    }
                } header: {
                    Text(section.teacher)
                        .themeFont(.listTitle)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func meditationRow(for meditation: GuidedMeditation) -> some View {
        HStack {
            HStack {
                self.previewPlayIcon(for: meditation)

                VStack(alignment: .leading, spacing: 4) {
                    Text(meditation.effectiveName)
                        .themeFont(.listActionLabel)
                    Text(meditation.formattedDuration)
                        .themeFont(.listSubtitle)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .gesture(self.previewOrNavigateGesture(for: meditation))

            self.overflowMenu(for: meditation)
        }
        .padding(.vertical, 4)
        .cardRowBackground()
        .accessibilityHint("accessibility.library.row.hint")
        .accessibilityIdentifier("library.row.meditation.\(meditation.id.uuidString)")
    }

    /// Short tap → navigate to player, long press (0.4s) → audio preview
    private func previewOrNavigateGesture(
        for meditation: GuidedMeditation
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !self.isPressing else {
                    return
                }
                self.isPressing = true
                let work = DispatchWorkItem {
                    guard self.isPressing else {
                        return
                    }
                    self.longPressActive = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    self.viewModel.startPreview(for: meditation)
                }
                self.longPressWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
            }
            .onEnded { _ in
                self.longPressWork?.cancel()
                self.longPressWork = nil
                if self.longPressActive {
                    self.viewModel.stopPreview()
                } else {
                    self.navigationPath.append(meditation)
                }
                self.isPressing = false
                self.longPressActive = false
            }
    }

    private func previewPlayIcon(for meditation: GuidedMeditation) -> some View {
        let isThisPreviewing = self.viewModel.previewingMeditationId == meditation.id
        return Image(systemName: "play.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(self.theme.interactive)
            .scaleEffect(isThisPreviewing && self.isPressing ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: self.isPressing)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("accessibility.library.preview")
            .accessibilityHint("accessibility.library.preview.hint")
            .accessibilityIdentifier("library.button.preview.\(meditation.id.uuidString)")
    }

    private func overflowMenu(for meditation: GuidedMeditation) -> some View {
        Menu {
            Button {
                self.viewModel.showEditSheet(for: meditation)
            } label: {
                Label("guided_meditations.edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                self.meditationToDelete = meditation
            } label: {
                Label("guided_meditations.delete.confirm", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(self.theme.interactive)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("accessibility.library.overflow")
        .accessibilityHint("accessibility.library.overflow.hint")
        .accessibilityIdentifier("library.button.overflow.\(meditation.id.uuidString)")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Empty State") {
    NavigationStack {
        GuidedMeditationsListView()
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("With Meditations") {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}
#endif
