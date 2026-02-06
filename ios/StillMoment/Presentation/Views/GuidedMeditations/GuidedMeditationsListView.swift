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
        viewModel: GuidedMeditationsListViewModel? = nil,
        settingsRepository: GuidedSettingsRepository = GuidedMeditationSettingsRepository()
    ) {
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: GuidedMeditationsListViewModel())
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
        .navigationTitle("guided_meditations.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
                    self.showingSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .foregroundColor(self.theme.textSecondary)
                .accessibilityLabel("guided_meditations.settings")
                .accessibilityHint("accessibility.library.settings.hint")
                .accessibilityIdentifier("library.button.settings")
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
        .navigationDestination(for: GuidedMeditation.self) { meditation in
            GuidedMeditationPlayerView(
                meditation: meditation,
                preparationTimeSeconds: self.settings.preparationTimeSeconds
            )
        }
        .sheet(isPresented: self.$showingSettings) {
            GuidedMeditationSettingsView(settings: self.settings) { updatedSettings in
                self.settingsRepository.save(updatedSettings)
                self.settings = updatedSettings
                self.showingSettings = false
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
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @StateObject private var viewModel: GuidedMeditationsListViewModel
    @State private var meditationToDelete: GuidedMeditation?
    @State private var showingSettings = false
    @State private var settings: GuidedMeditationSettings

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
                .fill(self.theme.backgroundPrimary)
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
        ZStack {
            NavigationLink(value: meditation) { EmptyView() }
                .opacity(0)

            HStack {
                Image(systemName: "play.circle")
                    .font(.system(size: 20))
                    .foregroundColor(self.theme.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(meditation.effectiveName)
                        .themeFont(.listActionLabel)
                    Text(meditation.formattedDuration)
                        .themeFont(.listSubtitle)
                }

                Spacer()

                self.overflowMenu(for: meditation)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(self.theme.backgroundPrimary)
        .accessibilityHint("accessibility.library.row.hint")
        .accessibilityIdentifier("library.row.meditation.\(meditation.id.uuidString)")
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

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        // MARK: Lifecycle

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        // MARK: Internal

        let onPick: (URL) -> Void

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                return
            }
            self.onPick(url)
        }
    }

    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio, .mp3],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: self.onPick)
    }
}

// MARK: - UTType Extension

extension UTType {
    static let mp3 = UTType(filenameExtension: "mp3") ?? .audio
}

// MARK: - Previews

// Preview-only mock service
#if DEBUG
private final class PreviewMeditationService: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation]

    init(meditations: [GuidedMeditation] = []) {
        self.meditations = meditations
    }

    func loadMeditations() throws -> [GuidedMeditation] {
        self.meditations
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        self.meditations = meditations
    }

    func addMeditation(from _: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "preview.mp3",
            fileName: "preview.mp3",
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown",
            name: metadata.title ?? "Untitled"
        )
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {}

    func deleteMeditation(id: UUID) throws {}

    func getMeditationsDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }

    func needsMigration() -> Bool {
        false
    }

    /// Sample data for previews
    static let sampleMeditations: [GuidedMeditation] = [
        GuidedMeditation(
            localFilePath: "sample1.mp3",
            fileName: "loving-kindness.mp3",
            duration: 691, // 11:31
            teacher: "Christine Braehler",
            name: "Loving-without-Losing-Yourself"
        ),
        GuidedMeditation(
            localFilePath: "sample2.mp3",
            fileName: "einschlafen.mp3",
            duration: 3629, // 1:00:29
            teacher: "Somebody",
            name: "Meditation wieder Einschlafen bei naechtlichem Erwachen"
        ),
        GuidedMeditation(
            localFilePath: "sample3.mp3",
            fileName: "body-scan.mp3",
            duration: 1245, // 20:45
            teacher: "Christine Braehler",
            name: "Body Scan Meditation"
        )
    ]
}
#endif

#if DEBUG
@available(iOS 17.0, *)
#Preview("Empty State") {
    NavigationStack {
        GuidedMeditationsListView()
    }
}

@available(iOS 17.0, *)
#Preview("With Meditations") {
    NavigationStack {
        GuidedMeditationsListView(
            viewModel: GuidedMeditationsListViewModel(
                meditationService: PreviewMeditationService(
                    meditations: PreviewMeditationService.sampleMeditations
                )
            )
        )
    }
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        GuidedMeditationsListView(
            viewModel: GuidedMeditationsListViewModel(
                meditationService: PreviewMeditationService(
                    meditations: PreviewMeditationService.sampleMeditations
                )
            )
        )
    }
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    NavigationStack {
        GuidedMeditationsListView(
            viewModel: GuidedMeditationsListViewModel(
                meditationService: PreviewMeditationService(
                    meditations: PreviewMeditationService.sampleMeditations
                )
            )
        )
    }
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    NavigationStack {
        GuidedMeditationsListView(
            viewModel: GuidedMeditationsListViewModel(
                meditationService: PreviewMeditationService(
                    meditations: PreviewMeditationService.sampleMeditations
                )
            )
        )
    }
}
#endif
