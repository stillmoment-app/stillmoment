//
//  EditSheetState.swift
//  Still Moment
//
//  Domain Model - Edit Sheet State
//

import Foundation

/// Manages state and validation logic for editing guided meditation metadata
///
/// This struct extracts testable business logic from the UI layer,
/// enabling unit testing without SwiftUI dependencies.
///
/// Usage:
/// ```swift
/// var state = EditSheetState(meditation: meditation)
/// state.editedTeacher = "New Teacher"
/// if state.isValid && state.hasChanges {
///     let updated = state.applyChanges()
/// }
/// ```
struct EditSheetState {
    // MARK: Lifecycle

    /// Initializes edit state from a meditation
    ///
    /// - Parameter meditation: The meditation to edit
    init(meditation: GuidedMeditation) {
        self.originalMeditation = meditation
        self.editedTeacher = meditation.effectiveTeacher
        self.editedName = meditation.effectiveName
    }

    // MARK: Internal

    /// The original meditation being edited
    let originalMeditation: GuidedMeditation

    /// Current edited teacher value
    var editedTeacher: String

    /// Current edited name value
    var editedName: String

    /// Whether changes have been made compared to original values
    var hasChanges: Bool {
        self.editedTeacher != self.originalMeditation.teacher ||
            self.editedName != self.originalMeditation.name
    }

    /// Whether the current values are valid for saving
    var isValid: Bool {
        !self.editedTeacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Creates an updated meditation with the edited values
    ///
    /// Only sets customTeacher/customName if values differ from original.
    ///
    /// - Returns: Updated meditation with applied changes
    func applyChanges() -> GuidedMeditation {
        var updated = self.originalMeditation

        // Only set custom values if they differ from original
        updated.customTeacher = self.editedTeacher != self.originalMeditation.teacher
            ? self.editedTeacher
            : nil
        updated.customName = self.editedName != self.originalMeditation.name
            ? self.editedName
            : nil

        return updated
    }

    /// Resets edited values to original meditation values
    mutating func reset() {
        self.editedTeacher = self.originalMeditation.teacher
        self.editedName = self.originalMeditation.name
    }
}
