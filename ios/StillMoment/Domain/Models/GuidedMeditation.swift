//
//  GuidedMeditation.swift
//  Still Moment
//
//  Domain Model - Guided Meditation
//

import Foundation

/// Represents a guided meditation audio file with metadata
///
/// This model stores references to external MP3 files via security-scoped bookmarks,
/// allowing the app to access files in the user's file system (iCloud Drive, etc.)
/// without copying them into the app sandbox.
///
/// Metadata can be customized by the user, overriding values read from ID3 tags.
struct GuidedMeditation: Identifiable, Codable, Equatable {
    // MARK: Lifecycle

    /// Initializes a new guided meditation
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - fileBookmark: Security-scoped bookmark data
    ///   - fileName: Original file name
    ///   - duration: Duration in seconds
    ///   - teacher: Teacher/Artist name
    ///   - name: Meditation name/title
    ///   - customTeacher: Optional custom teacher name
    ///   - customName: Optional custom meditation name
    ///   - dateAdded: Date added (defaults to now)
    init(
        id: UUID = UUID(),
        fileBookmark: Data,
        fileName: String,
        duration: TimeInterval,
        teacher: String,
        name: String,
        customTeacher: String? = nil,
        customName: String? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.fileBookmark = fileBookmark
        self.fileName = fileName
        self.duration = duration
        self.teacher = teacher
        self.name = name
        self.customTeacher = customTeacher
        self.customName = customName
        self.dateAdded = dateAdded
    }

    // MARK: Internal

    /// Unique identifier
    let id: UUID

    /// Security-scoped bookmark data for accessing the file
    let fileBookmark: Data

    /// Original file name (for debugging/display purposes)
    let fileName: String

    /// Duration in seconds (read from audio file)
    let duration: TimeInterval

    /// Teacher/Artist name (from ID3 tag or user-edited)
    var teacher: String

    /// Meditation name/title (from ID3 tag or user-edited)
    var name: String

    /// Custom teacher name set by user (overrides ID3 tag)
    var customTeacher: String?

    /// Custom meditation name set by user (overrides ID3 tag)
    var customName: String?

    /// Date when the meditation was added to the library
    let dateAdded: Date

    /// Returns the effective teacher name (custom if set, otherwise original)
    var effectiveTeacher: String {
        self.customTeacher ?? self.teacher
    }

    /// Returns the effective meditation name (custom if set, otherwise original)
    var effectiveName: String {
        self.customName ?? self.name
    }

    /// Formatted duration string (MM:SS or HH:MM:SS)
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
