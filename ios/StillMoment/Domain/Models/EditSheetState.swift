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
        self.editedTrimStartText = meditation.trimStart.map(Self.formatTime) ?? ""
        self.editedTrimEndText = meditation.trimEnd.map(Self.formatTime) ?? ""
    }

    // MARK: Internal

    let originalMeditation: GuidedMeditation

    var editedTeacher: String

    var editedName: String

    /// Trim start as text (m:ss, h:mm:ss, or plain minutes; empty = no trim)
    var editedTrimStartText: String

    /// Trim end as text (m:ss, h:mm:ss, or plain minutes; empty = no trim)
    var editedTrimEndText: String

    /// Whether the user changed teacher, name, or trim points compared to the initial values.
    var hasChanges: Bool {
        self.editedTeacher != self.originalMeditation.teacher ||
            self.editedName != self.originalMeditation.name ||
            self.parsedTrimStart.value != self.originalMeditation.trimStart ||
            self.parsedTrimEnd.value != self.originalMeditation.trimEnd
    }

    /// Whether all fields contain valid input (non-empty teacher/name, consistent trim points).
    var isValid: Bool {
        !self.editedTeacher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            self.isTrimInputValid
    }

    /// Parsed trim start in seconds (nil if empty or unparseable)
    var trimStartValue: TimeInterval? {
        self.parsedTrimStart.value
    }

    /// Parsed trim end in seconds (nil if empty or unparseable)
    var trimEndValue: TimeInterval? {
        self.parsedTrimEnd.value
    }

    /// Whether the trim fields parse and describe a consistent range within the file.
    var isTrimInputValid: Bool {
        let start = self.parsedTrimStart
        let end = self.parsedTrimEnd

        guard !start.isInvalid, !end.isInvalid else {
            return false
        }

        let duration = self.originalMeditation.duration
        if let startValue = start.value {
            guard startValue < duration else {
                return false
            }
        }
        if let endValue = end.value {
            guard endValue > 0, endValue <= duration else {
                return false
            }
        }
        if let startValue = start.value, let endValue = end.value {
            guard startValue < endValue else {
                return false
            }
        }
        return true
    }

    /// Returns the original meditation with the edited values applied.
    func applyChanges() -> GuidedMeditation {
        var updated = self.originalMeditation
        updated.teacher = self.editedTeacher
        updated.name = self.editedName
        updated.trimStart = self.parsedTrimStart.value
        updated.trimEnd = self.parsedTrimEnd.value
        return updated
    }

    // MARK: Private

    /// Result of parsing a trim text field: empty (no trim), a value, or unparseable input.
    private enum TrimParseResult {
        case empty
        case value(TimeInterval)
        case invalid

        var value: TimeInterval? {
            if case let .value(seconds) = self {
                return seconds
            }
            return nil
        }

        var isInvalid: Bool {
            if case .invalid = self {
                return true
            }
            return false
        }
    }

    private var parsedTrimStart: TrimParseResult {
        Self.parseTime(self.editedTrimStartText)
    }

    private var parsedTrimEnd: TrimParseResult {
        Self.parseTime(self.editedTrimEndText)
    }

    /// Parses "h:mm:ss", "m:ss", or a plain number (minutes) into seconds.
    private static func parseTime(_ text: String) -> TrimParseResult {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return .empty
        }

        let parts = trimmed.components(separatedBy: ":")
        let numbers = parts.map { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.allSatisfy({ $0 != nil }) else {
            return .invalid
        }
        let values = numbers.compactMap { $0 }
        guard values.allSatisfy({ $0 >= 0 }) else {
            return .invalid
        }

        switch values.count {
        case 1:
            return .value(TimeInterval(values[0] * 60))
        case 2:
            guard values[1] < 60 else {
                return .invalid
            }
            return .value(TimeInterval(values[0] * 60 + values[1]))
        case 3:
            guard values[1] < 60, values[2] < 60 else {
                return .invalid
            }
            return .value(TimeInterval(values[0] * 3600 + values[1] * 60 + values[2]))
        default:
            return .invalid
        }
    }

    /// Formats seconds as "m:ss" or "h:mm:ss" for prefilling the text fields.
    private static func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
