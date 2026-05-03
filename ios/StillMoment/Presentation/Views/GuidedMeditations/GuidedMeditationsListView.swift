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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.viewModel.openGuideSheet(languageCode: self.currentLanguageCode)
                } label: {
                    Image(systemName: "info.circle")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .foregroundColor(self.theme.textSecondary)
                .accessibilityLabel("guided_meditations.guide.info")
                .accessibilityIdentifier("library.button.guide")
            }
        }
        .sheet(isPresented: self.$viewModel.showingDocumentPicker) {
            DocumentPicker { url in
                Task {
                    await self.viewModel.importMeditation(from: url)
                }
            }
        }
        .sheet(isPresented: self.$viewModel.showingGuideSheet) {
            ThemeRootView {
                NavigationStack {
                    ContentGuideSheet(
                        sources: self.viewModel.guideSources,
                        onDismiss: self.viewModel.closeGuideSheet
                    )
                }
            }
            .environmentObject(self.fileOpenHandler)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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

    private let meditationService: GuidedMeditationServiceProtocol
    private let settingsRepository: GuidedSettingsRepository

    private var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

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
        VStack(spacing: 0) {
            self.waveformGlyph
                .padding(.bottom, 32)

            Text("guided_meditations.empty.title")
                .themeFont(.screenTitle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.bottom, 14)

            Text("guided_meditations.empty.message")
                .themeFont(.bodySecondary, color: \.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.bottom, 36)

            Button {
                self.viewModel.showDocumentPicker()
            } label: {
                Label("guided_meditations.import", systemImage: "plus")
            }
            .warmPrimaryButton()
            .accessibilityHint("accessibility.library.import.hint")
            .accessibilityIdentifier("library.button.import.emptyState")

            Button {
                self.viewModel.openGuideSheet(languageCode: self.currentLanguageCode)
            } label: {
                Text("guided_meditations.empty.findSources")
                    .themeFont(.bodySecondary, color: \.interactive)
                    .underline(true, color: self.theme.interactive.opacity(.opacitySecondary))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .accessibilityIdentifier("library.button.findSources.emptyState")
        }
        .padding(.horizontal, 36)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var waveformGlyph: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            self.theme.interactive.opacity(0.18),
                            self.theme.interactive.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            Image(systemName: "waveform")
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(self.theme.interactive)
                .accessibilityHidden(true)
        }
    }

    private var meditationsList: some View {
        List {
            ForEach(self.viewModel.meditationsByTeacher(), id: \.teacher) { section in
                Section {
                    ForEach(section.meditations) { meditation in
                        self.meditationRow(for: meditation)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    self.meditationToDelete = meditation
                                } label: {
                                    Label("guided_meditations.delete.confirm", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    self.viewModel.showEditSheet(for: meditation)
                                } label: {
                                    Label("guided_meditations.edit", systemImage: "pencil")
                                }
                                .tint(self.theme.interactive)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.effectiveName)
                    .themeFont(.listActionLabel)
                Text(meditation.formattedDuration)
                    .themeFont(.listSubtitle)
            }

            Spacer()

            self.playButton(for: meditation)
        }
        .padding(.vertical, 4)
        .cardRowBackground()
        .accessibilityIdentifier("library.row.meditation.\(meditation.id.uuidString)")
    }

    /// Play button with two interactions:
    /// - Tap → start meditation (navigate to player) or stop preview
    /// - Long press → start preview
    private func playButton(for meditation: GuidedMeditation) -> some View {
        let isThisPreviewing = self.viewModel.previewingMeditationId == meditation.id

        return Image(systemName: isThisPreviewing ? "stop.circle.fill" : "play.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(self.theme.interactive)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                if isThisPreviewing {
                    self.viewModel.stopPreview()
                } else {
                    self.viewModel.stopPreview()
                    self.navigationPath.append(meditation)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self.viewModel.startPreview(for: meditation)
            }
            .accessibilityLabel(isThisPreviewing ? "accessibility.library.stop" : "accessibility.library.preview")
            .accessibilityHint(isThisPreviewing ? "accessibility.library.stop.hint" :
                "accessibility.library.preview.hint")
            .accessibilityIdentifier("library.button.preview.\(meditation.id.uuidString)")
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
