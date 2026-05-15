//
//  EditSheetState.swift
//  Still Moment
//
//  Domain Model - Edit Sheet State
//

import Foundation

/// Manages state and validation logic for editing guided meditation metadata.
///
/// Holds the editable fields and a snapshot of the original meditation so the view
/// can detect changes, validate input, and produce an updated `GuidedMeditation`
/// without owning persistence.
struct EditSheetState {
    // MARK: Lifecycle

    init(meditation: GuidedMeditation) {
        self.originalMeditation = meditation
        self.editedTeacher = meditation.teacher
        self.editedName = meditation.name
    }

    // MARK: Internal

    let originalMeditation: GuidedMeditation

    var editedTeacher: String

    var editedName: String

    /// Whether the user changed the teacher or name compared to the initial values.
    var hasChanges: Bool {
        self.editedTeacher != self.originalMeditation.teacher ||
            self.editedName != self.originalMeditation.name
    }

    /// Whether both fields contain non-whitespace input.
    var isValid: Bool {
        !self.editedTeacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns the original meditation with `teacher` and `name` replaced by the edited values.
    func applyChanges() -> GuidedMeditation {
        var updated = self.originalMeditation
        updated.teacher = self.editedTeacher
        updated.name = self.editedName
        return updated
    }
}
