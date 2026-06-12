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
///
/// Trim points are seconds (`nil` = no trim). They are committed by the waveform trim
/// editor (shared-107), which clamps every value — so this state only keeps a simple
/// defensive consistency check.
struct EditSheetState {
    // MARK: Lifecycle

    init(meditation: GuidedMeditation) {
        self.originalMeditation = meditation
        self.editedTeacher = meditation.teacher
        self.editedName = meditation.name
        self.editedTrimStart = meditation.trimStart
        self.editedTrimEnd = meditation.trimEnd
        self.editedStartGongEnabled = meditation.startGongEnabled
        self.editedEndGongEnabled = meditation.endGongEnabled
        self.editedGongSoundId = meditation.gongSoundId
    }

    // MARK: Internal

    let originalMeditation: GuidedMeditation

    var editedTeacher: String

    var editedName: String

    /// Playback start offset in seconds (nil = no trim); set by the trim editor.
    var editedTrimStart: TimeInterval?

    /// Playback end offset in seconds (nil = no trim); set by the trim editor.
    var editedTrimEnd: TimeInterval?

    /// Whether a gong should mark the start of playback (shared-106)
    var editedStartGongEnabled: Bool

    /// Whether a gong should mark the end of playback (independent of the start gong)
    var editedEndGongEnabled: Bool

    /// Gong sound chosen for this meditation (independent of the timer settings)
    var editedGongSoundId: String

    /// Whether the user changed teacher, name, trim points, or the gong settings.
    var hasChanges: Bool {
        self.editedTeacher != self.originalMeditation.teacher ||
            self.editedName != self.originalMeditation.name ||
            self.editedTrimStart != self.originalMeditation.trimStart ||
            self.editedTrimEnd != self.originalMeditation.trimEnd ||
            self.editedStartGongEnabled != self.originalMeditation.startGongEnabled ||
            self.editedEndGongEnabled != self.originalMeditation.endGongEnabled ||
            self.editedGongSoundId != self.originalMeditation.gongSoundId
    }

    /// Whether all fields contain valid input (non-empty teacher/name, consistent trim points).
    var isValid: Bool {
        !self.editedTeacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            self.isTrimConsistent
    }

    /// Returns the original meditation with the edited values applied.
    func applyChanges() -> GuidedMeditation {
        var updated = self.originalMeditation
        updated.teacher = self.editedTeacher
        updated.name = self.editedName
        updated.trimStart = self.editedTrimStart
        updated.trimEnd = self.editedTrimEnd
        updated.startGongEnabled = self.editedStartGongEnabled
        updated.endGongEnabled = self.editedEndGongEnabled
        updated.gongSoundId = self.editedGongSoundId
        return updated
    }

    /// Formats seconds as "m:ss" or "h:mm:ss" for display.
    static func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // MARK: Private

    /// Defensive consistency check: trim points must lie inside the file with start < end.
    /// Values normally come from the editor's clamping, so this only guards against bad input.
    private var isTrimConsistent: Bool {
        let duration = self.originalMeditation.duration
        if let start = self.editedTrimStart {
            guard start >= 0, start < duration else {
                return false
            }
        }
        if let end = self.editedTrimEnd {
            guard end > 0, end <= duration else {
                return false
            }
        }
        if let start = self.editedTrimStart, let end = self.editedTrimEnd {
            guard start < end else {
                return false
            }
        }
        return true
    }
}
