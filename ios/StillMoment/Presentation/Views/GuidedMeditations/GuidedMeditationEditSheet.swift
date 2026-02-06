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

        // Initialize edit state with meditation
        _editState = State(initialValue: EditSheetState(meditation: meditation))
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
                self.theme.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("guided_meditations.edit.teacher")
                                .themeFont(.editLabel)

                            AutocompleteTextField(
                                text: self.$editState.editedTeacher,
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
                                .themeFont(.editLabel)

                            TextField("guided_meditations.edit.namePlaceholder", text: self.$editState.editedName)
                                .accessibilityLabel("guided_meditations.edit.name")
                                .accessibilityIdentifier("editSheet.field.name")
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("guided_meditations.edit.file")
                                    .themeFont(.editLabel)
                                Spacer()
                                Text(self.meditation.fileName)
                                    .themeFont(.editCaption)
                            }

                            HStack {
                                Text("guided_meditations.edit.duration")
                                    .themeFont(.editLabel)
                                Spacer()
                                Text(self.meditation.formattedDuration)
                                    .themeFont(.editCaption)
                            }
                        }
                    } header: {
                        Text("guided_meditations.edit.fileInfo")
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
                    .foregroundColor(self.theme.textSecondary)
                    .accessibilityIdentifier("editSheet.button.cancel")
                    .accessibilityHint("accessibility.editSheet.cancel.hint")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "")) {
                        self.onSave(self.editState.applyChanges())
                    }
                    .tint(self.theme.interactive)
                    .accessibilityIdentifier("editSheet.button.save")
                    .accessibilityHint("accessibility.editSheet.save.hint")
                    .disabled(!self.editState.isValid)
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @State private var editState: EditSheetState
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
