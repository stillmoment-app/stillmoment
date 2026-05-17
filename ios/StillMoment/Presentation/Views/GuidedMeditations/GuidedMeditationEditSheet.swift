//
//  GuidedMeditationEditSheet.swift
//  Still Moment
//
//  Presentation Layer - Guided Meditation Edit Sheet (ios-044)
//

import SwiftUI

/// Mode of operation for `GuidedMeditationEditSheet`.
///
/// The view is structurally identical in both modes; only the save-button label and the
/// autofocus rule differ. Persistence (`addMeditation` vs. `updateMeditation`) is handled
/// by the caller via the `onSave` closure.
enum GuidedMeditationEditSheetMode {
    /// Import flow — the meditation is a draft and has not been persisted yet.
    case importMode
    /// Edit flow — the meditation already exists in the library.
    case edit

    /// Localized key for the confirmation button label.
    var saveButtonKey: String {
        switch self {
        case .importMode: "guided_meditations.import.action"
        case .edit: "common.save"
        }
    }

    /// Decides whether the name field should auto-focus when the sheet appears.
    ///
    /// Import mode auto-focuses the name field only if the prefilled name is effectively
    /// empty (the user has nothing to confirm). Edit mode never auto-focuses, so the user
    /// first sees the persisted values.
    func shouldAutofocusName(prefilledName: String) -> Bool {
        guard self == .importMode else {
            return false
        }
        return prefilledName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Sheet for editing guided meditation metadata.
///
/// Used for both importing newly added files (where the meditation is a draft with prefilled
/// values) and editing existing library entries. Save and Cancel semantics are delegated to
/// the caller via closures.
struct GuidedMeditationEditSheet: View {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        mode: GuidedMeditationEditSheetMode = .edit,
        availableTeachers: [String] = [],
        onSave: @escaping (GuidedMeditation) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.meditation = meditation
        self.mode = mode
        self.availableTeachers = availableTeachers
        self.onSave = onSave
        self.onCancel = onCancel

        _editState = State(initialValue: EditSheetState(meditation: meditation))
    }

    // MARK: Internal

    let meditation: GuidedMeditation
    let mode: GuidedMeditationEditSheetMode
    let availableTeachers: [String]
    let onSave: (GuidedMeditation) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                self.theme.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        self.teacherField
                    }
                    Section {
                        self.nameField
                    } footer: {
                        self.fileInfoFooter
                    }
                }
                .scrollContentBackground(.hidden)
                .modifier(CompactSectionSpacingModifier())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(self.theme.textSecondary)
                    .accessibilityLabel("common.cancel")
                    .accessibilityIdentifier("editSheet.button.cancel")
                    .accessibilityHint("accessibility.editSheet.cancel.hint")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString(self.mode.saveButtonKey, comment: "")) {
                        self.attemptSave()
                    }
                    .tint(self.theme.interactive)
                    .accessibilityIdentifier("editSheet.button.save")
                    .accessibilityHint("accessibility.editSheet.save.hint")
                    .disabled(!self.editState.isValid)
                }
            }
            .onAppear {
                self.applyAutofocus()
            }
        }
    }

    // MARK: - Subviews

    private var teacherField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("guided_meditations.edit.teacher")
                .textStyle(.eyebrow, color: \.textPrimary)

            AutocompleteTextField(
                text: self.$editState.editedTeacher,
                focus: self.$teacherFocused,
                placeholder: "guided_meditations.edit.teacherPlaceholder",
                suggestions: self.availableTeachers,
                accessibilityLabel: "guided_meditations.edit.teacher",
                accessibilityIdentifier: "editSheet.field.teacher",
                submitLabel: .next
            ) {
                self.nameFocused = true
            }
            .accessibilityHint(self.requiredHintIfEmpty(self.editState.editedTeacher))
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("guided_meditations.edit.name")
                .textStyle(.eyebrow, color: \.textPrimary)

            ClearableTextField(
                "guided_meditations.edit.namePlaceholder",
                text: self.$editState.editedName,
                focus: self.$nameFocused,
                accessibilityLabel: "guided_meditations.edit.name",
                accessibilityIdentifier: "editSheet.field.name",
                submitLabel: .done,
                lineLimit: 1...3,
                onSubmit: self.attemptSave
            )
            .accessibilityHint(self.requiredHintIfEmpty(self.editState.editedName))
        }
    }

    private var fileInfoFooter: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "doc")
                .font(.system(size: 11))
                .foregroundColor(self.theme.textSecondary)
                .padding(.top, 2)
            (
                Text(self.meditation.fileName)
                    + Text(verbatim: "  ·  ")
                    + Text(self.meditation.formattedDuration)
            )
            .textStyle(.caption, color: \.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @State private var editState: EditSheetState
    @FocusState private var teacherFocused: Bool
    @FocusState private var nameFocused: Bool

    private func attemptSave() {
        guard self.editState.isValid else {
            return
        }
        self.onSave(self.editState.applyChanges())
    }

    private func applyAutofocus() {
        guard self.mode.shouldAutofocusName(prefilledName: self.editState.editedName) else {
            return
        }
        // Slight delay lets the sheet finish presenting before the keyboard pops up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.nameFocused = true
        }
    }

    private func requiredHintIfEmpty(_ value: String) -> LocalizedStringKey {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "accessibility.editSheet.requiredField.hint" : ""
    }
}

// MARK: - Helpers

/// Reduces the vertical gap between `Form` sections on iOS 17+.
///
/// Standard Form-section spacing is ~30pt — that breaks the visual rhythm between the
/// Lehrer and Name cards. iOS 16 falls back to the default; the gap is bigger there
/// but the layout remains correct.
private struct CompactSectionSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.listSectionSpacing(.compact)
        } else {
            content
        }
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
#Preview("Edit") {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        mode: .edit,
        availableTeachers: ["Jon Kabat-Zinn", "Jack Kornfield", "Tara Brach", "Joseph Goldstein"],
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("Import (Prefilled)") {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        mode: .importMode,
        availableTeachers: ["Jon Kabat-Zinn", "Tara Brach"],
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("Import (Empty Prefill)") {
    let draft = GuidedMeditation(
        localFilePath: "",
        fileName: "d067c0ea-2c04-b934.mp3",
        duration: 600,
        teacher: "",
        name: ""
    )
    return GuidedMeditationEditSheet(
        meditation: draft,
        mode: .importMode,
        availableTeachers: ["Jon Kabat-Zinn", "Tara Brach"],
        onSave: { _ in },
        onCancel: {}
    )
}
