//
//  GuidedMeditationEditSheet.swift
//  MediTimer
//
//  Presentation Layer - Guided Meditation Edit Sheet
//

import SwiftUI

/// Sheet for editing guided meditation metadata
///
/// Allows users to customize:
/// - Teacher name
/// - Meditation name
struct GuidedMeditationEditSheet: View {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        onSave: @escaping (GuidedMeditation) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.meditation = meditation
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize with current effective values
        _customTeacher = State(initialValue: meditation.effectiveTeacher)
        _customName = State(initialValue: meditation.effectiveName)
    }

    // MARK: Internal

    let meditation: GuidedMeditation
    let onSave: (GuidedMeditation) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("guided_meditations.edit.teacher")
                            .font(.subheadline.weight(.medium))

                        TextField("guided_meditations.edit.teacherPlaceholder", text: self.$customTeacher)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("guided_meditations.edit.teacher")

                        if self.meditation.teacher != self.customTeacher {
                            Text("guided_meditations.edit.original: \(self.meditation.teacher)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("guided_meditations.edit.name")
                            .font(.subheadline.weight(.medium))

                        TextField("guided_meditations.edit.namePlaceholder", text: self.$customName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("guided_meditations.edit.name")

                        if self.meditation.name != self.customName {
                            Text("guided_meditations.edit.original: \(self.meditation.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("guided_meditations.edit.file")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(self.meditation.fileName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("guided_meditations.edit.duration")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(self.meditation.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("guided_meditations.edit.fileInfo")
                }

                Section {
                    Button(role: .destructive) {
                        self.resetToOriginal()
                    } label: {
                        Text("guided_meditations.edit.reset")
                    }
                    .disabled(!self.hasChanges)
                }
            }
            .navigationTitle("guided_meditations.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        self.saveChanges()
                    }
                    .disabled(!self.isValid)
                }
            }
        }
    }

    // MARK: Private

    @State private var customTeacher: String
    @State private var customName: String

    private var hasChanges: Bool {
        self.customTeacher != self.meditation.teacher || self.customName != self.meditation.name
    }

    private var isValid: Bool {
        !self.customTeacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveChanges() {
        var updated = self.meditation

        // Only set custom values if they differ from original
        updated.customTeacher = self.customTeacher != self.meditation.teacher ? self.customTeacher : nil
        updated.customName = self.customName != self.meditation.name ? self.customName : nil

        self.onSave(updated)
    }

    private func resetToOriginal() {
        self.customTeacher = self.meditation.teacher
        self.customName = self.meditation.name
    }
}

// MARK: - Preview

#Preview {
    GuidedMeditationEditSheet(
        meditation: GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: "Jon Kabat-Zinn",
            name: "Body Scan Meditation"
        ),
        onSave: { _ in },
        onCancel: {}
    )
}
