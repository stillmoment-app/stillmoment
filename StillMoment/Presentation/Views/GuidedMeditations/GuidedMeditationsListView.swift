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
    // MARK: Internal

    var body: some View {
        ZStack {
            // Warm gradient background (consistent with Timer tab)
            Color.warmGradient
                .ignoresSafeArea()

            if self.viewModel.meditations.isEmpty {
                self.emptyStateView
            } else {
                self.meditationsList
            }

            if self.viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .navigationTitle("guided_meditations.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.viewModel.showDocumentPicker()
                } label: {
                    Image(systemName: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .foregroundColor(.warmGray)
                .accessibilityLabel("guided_meditations.add")
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
        .sheet(item: self.$selectedMeditation) { meditation in
            GuidedMeditationPlayerView(meditation: meditation)
        }
        .alert("Error", isPresented: .constant(self.viewModel.errorMessage != nil)) {
            Button("OK") {
                self.viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            self.viewModel.loadMeditations()
        }
    }

    // MARK: Private

    @StateObject private var viewModel = GuidedMeditationsListViewModel()
    @State private var selectedMeditation: GuidedMeditation?

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60, design: .rounded))
                .foregroundColor(Color.terracotta)

            Text("guided_meditations.empty.title")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundColor(.warmBlack)

            Text("guided_meditations.empty.message")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.warmGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                self.viewModel.showDocumentPicker()
            } label: {
                Label("guided_meditations.import", systemImage: "plus.circle.fill")
            }
            .warmPrimaryButton()
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
                        for index in indexSet {
                            self.viewModel.deleteMeditation(section.meditations[index])
                        }
                    }
                } header: {
                    Text(section.teacher)
                        .font(.system(.headline, design: .rounded))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func meditationRow(for meditation: GuidedMeditation) -> some View {
        Button {
            self.selectedMeditation = meditation
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meditation.effectiveName)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.primary)

                    Text(meditation.formattedDuration)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    self.viewModel.showEditSheet(for: meditation)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(Color.terracotta)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("guided_meditations.edit")
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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

// MARK: - Preview

#Preview {
    GuidedMeditationsListView()
}
