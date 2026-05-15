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
struct GuidedMeditation: Identifiable, Codable, Equatable, Hashable {
    // MARK: Lifecycle

    /// Initializes a new guided meditation with a local file path (preferred)
    init(
        id: UUID = UUID(),
        localFilePath: String,
        fileName: String,
        duration: TimeInterval,
        teacher: String,
        name: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.localFilePath = localFilePath
        self.fileBookmark = nil
        self.fileName = fileName
        self.duration = duration
        self.teacher = teacher
        self.name = name
        self.dateAdded = dateAdded
    }

    /// Legacy initializer for security-scoped bookmarks (migration support)
    init(
        id: UUID = UUID(),
        fileBookmark: Data,
        fileName: String,
        duration: TimeInterval,
        teacher: String,
        name: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.localFilePath = nil
        self.fileBookmark = fileBookmark
        self.fileName = fileName
        self.duration = duration
        self.teacher = teacher
        self.name = name
        self.dateAdded = dateAdded
    }

    // MARK: - Codable

    /// Decodes a meditation; legacy `customTeacher`/`customName` overrides are folded into
    /// `teacher`/`name` so the rest of the app sees a single source of truth.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.localFilePath = try container.decodeIfPresent(String.self, forKey: .localFilePath)
        self.fileBookmark = try container.decodeIfPresent(Data.self, forKey: .fileBookmark)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.dateAdded = try container.decode(Date.self, forKey: .dateAdded)

        let originalTeacher = try container.decode(String.self, forKey: .teacher)
        let originalName = try container.decode(String.self, forKey: .name)
        let legacyCustomTeacher = try container.decodeIfPresent(String.self, forKey: .customTeacher)
        let legacyCustomName = try container.decodeIfPresent(String.self, forKey: .customName)

        self.teacher = legacyCustomTeacher ?? originalTeacher
        self.name = legacyCustomName ?? originalName
    }

    /// Encodes the meditation without the legacy `customTeacher`/`customName` fields.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.localFilePath, forKey: .localFilePath)
        try container.encodeIfPresent(self.fileBookmark, forKey: .fileBookmark)
        try container.encode(self.fileName, forKey: .fileName)
        try container.encode(self.duration, forKey: .duration)
        try container.encode(self.teacher, forKey: .teacher)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.dateAdded, forKey: .dateAdded)
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

    /// Date when the meditation was added to the library
    let dateAdded: Date

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
            dateAdded: self.dateAdded
        )
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case id
        case localFilePath
        case fileBookmark
        case fileName
        case duration
        case teacher
        case name
        case dateAdded
        // Legacy keys (read-only during migration; no longer encoded)
        case customTeacher
        case customName
    }
}
