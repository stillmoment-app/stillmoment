//
//  GuidedMeditationEditSheet.swift
//  Still Moment
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
        availableTeachers: [String] = [],
        onSave: @escaping (GuidedMeditation) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.meditation = meditation
        self.availableTeachers = availableTeachers
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize with current effective values
        _customTeacher = State(initialValue: meditation.effectiveTeacher)
        _customName = State(initialValue: meditation.effectiveName)
    }

    // MARK: Internal

    let meditation: GuidedMeditation
    let availableTeachers: [String]
    let onSave: (GuidedMeditation) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background (consistent with other views)
                Color.warmGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("guided_meditations.edit.teacher")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.textPrimary)

                            AutocompleteTextField(
                                text: self.$customTeacher,
                                placeholder: "guided_meditations.edit.teacherPlaceholder",
                                suggestions: self.availableTeachers,
                                accessibilityLabel: "guided_meditations.edit.teacher",
                                accessibilityIdentifier: "editSheet.field.teacher"
                            )
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("guided_meditations.edit.name")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.textPrimary)

                            TextField("guided_meditations.edit.namePlaceholder", text: self.$customName)
                                .accessibilityLabel("guided_meditations.edit.name")
                                .accessibilityIdentifier("editSheet.field.name")
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("guided_meditations.edit.file")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(self.meditation.fileName)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }

                            HStack {
                                Text("guided_meditations.edit.duration")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(self.meditation.formattedDuration)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.textSecondary)
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
                        .accessibilityIdentifier("editSheet.button.reset")
                        .disabled(!self.hasChanges)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("guided_meditations.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        self.onCancel()
                    }
                    .foregroundColor(.textSecondary)
                    .accessibilityIdentifier("editSheet.button.cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "")) {
                        self.saveChanges()
                    }
                    .tint(.interactive)
                    .accessibilityIdentifier("editSheet.button.save")
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

// MARK: - Previews

private let previewMeditation = GuidedMeditation(
    fileBookmark: Data(),
    fileName: "test.mp3",
    duration: 600,
    teacher: "Jon Kabat-Zinn",
    name: "Body Scan Meditation"
)

@available(iOS 17.0, *)
#Preview("Default") {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        availableTeachers: ["Jon Kabat-Zinn", "Jack Kornfield", "Tara Brach", "Joseph Goldstein"],
        onSave: { _ in },
        onCancel: {}
    )
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        onSave: { _ in },
        onCancel: {}
    )
}
