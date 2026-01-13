//
//  GuidedMeditationTestHelpers.swift
//  Still Moment
//
//  Shared test utilities for GuidedMeditation tests
//

import Foundation
@testable import StillMoment

/// Helper functions for creating test data in GuidedMeditation tests
enum GuidedMeditationTestHelpers {
    /// Creates a temporary audio file for testing
    ///
    /// - Returns: URL to a temporary file that should be deleted in tearDown
    static func createTemporaryAudioFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_audio_\(UUID().uuidString).mp3")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        return fileURL
    }

    /// Creates a test meditation with a local file path
    ///
    /// - Parameters:
    ///   - fileURL: URL to an existing file to copy into the Meditations directory
    ///   - teacher: Optional teacher name (default: "Test Teacher")
    ///   - name: Optional meditation name (default: "Test Meditation")
    ///   - duration: Optional duration in seconds (default: 600)
    /// - Returns: A GuidedMeditation instance with the file accessible
    static func createTestMeditation(
        fileURL: URL,
        teacher: String = "Test Teacher",
        name: String = "Test Meditation",
        duration: TimeInterval = 600
    ) -> GuidedMeditation {
        let meditationId = UUID()
        let localFileName = "\(meditationId.uuidString).mp3"

        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let meditationsDir = appSupport.appendingPathComponent("Meditations")
            try? fileManager.createDirectory(at: meditationsDir, withIntermediateDirectories: true)
            let targetURL = meditationsDir.appendingPathComponent(localFileName)
            try? fileManager.removeItem(at: targetURL)
            try? fileManager.copyItem(at: fileURL, to: targetURL)
        }

        return GuidedMeditation(
            id: meditationId,
            localFilePath: localFileName,
            fileName: "test.mp3",
            duration: duration,
            teacher: teacher,
            name: name
        )
    }

    /// Cleans up a temporary audio file
    ///
    /// - Parameter url: URL to the file to remove
    static func cleanupTemporaryFile(_ url: URL?) {
        guard let url else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }

    /// Cleans up preparation time settings from UserDefaults
    static func cleanupUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "guidedMeditation.preparationTimeSeconds")
    }
}
