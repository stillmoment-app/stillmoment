//
//  GuidedMeditation.swift
//  Still Moment
//
//  Domain Model - Guided Meditation
//

import Foundation

/// Represents a guided meditation audio file with metadata
///
/// Audio files are stored locally in the app's Application Support/Meditations directory.
/// Legacy installations may have security-scoped bookmarks which are migrated on first launch.
///
/// Metadata can be customized by the user, overriding values read from ID3 tags.
struct GuidedMeditation: Identifiable, Codable, Equatable, Hashable {
    // MARK: Lifecycle

    /// Initializes a new guided meditation with a local file path (preferred)
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - localFilePath: Relative path within Application Support/Meditations/
    ///   - fileName: Original file name
    ///   - duration: Duration in seconds
    ///   - teacher: Teacher/Artist name
    ///   - name: Meditation name/title
    ///   - customTeacher: Optional custom teacher name
    ///   - customName: Optional custom meditation name
    ///   - dateAdded: Date added (defaults to now)
    init(
        id: UUID = UUID(),
        localFilePath: String,
        fileName: String,
        duration: TimeInterval,
        teacher: String,
        name: String,
        customTeacher: String? = nil,
        customName: String? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.localFilePath = localFilePath
        self.fileBookmark = nil
        self.fileName = fileName
        self.duration = duration
        self.teacher = teacher
        self.name = name
        self.customTeacher = customTeacher
        self.customName = customName
        self.dateAdded = dateAdded
    }

    /// Legacy initializer for security-scoped bookmarks (migration support)
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
        self.localFilePath = nil
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

    /// Relative path within Application Support/Meditations/ (new storage approach)
    let localFilePath: String?

    /// Security-scoped bookmark data for accessing the file (legacy, for migration)
    let fileBookmark: Data?

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

    /// Returns the URL to the local audio file
    ///
    /// Uses localFilePath if available, otherwise returns nil.
    /// Legacy bookmarks must be migrated before accessing.
    var fileURL: URL? {
        guard let localFilePath else {
            return nil
        }
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }
        return appSupport.appendingPathComponent("Meditations").appendingPathComponent(localFilePath)
    }

    /// Returns true if this meditation needs migration from bookmark to local file
    var needsMigration: Bool {
        self.localFilePath == nil && self.fileBookmark != nil
    }

    /// Creates a copy with the local file path set (for migration)
    func withLocalFilePath(_ path: String) -> GuidedMeditation {
        GuidedMeditation(
            id: self.id,
            localFilePath: path,
            fileName: self.fileName,
            duration: self.duration,
            teacher: self.teacher,
            name: self.name,
            customTeacher: self.customTeacher,
            customName: self.customName,
            dateAdded: self.dateAdded
        )
    }
}
