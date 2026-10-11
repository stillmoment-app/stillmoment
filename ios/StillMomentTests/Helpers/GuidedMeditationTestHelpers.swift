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
    /// Creates a test meditation with a local file path.
    ///
    /// No audio file is written: the player tests run on `MockGuidedMeditationService`
    /// and `MockAudioPlayerService`, which never open it (ios-056: tests stay out of
    /// the app's real Meditations folder).
    ///
    /// - Parameters:
    ///   - teacher: Optional teacher name (default: "Test Teacher")
    ///   - name: Optional meditation name (default: "Test Meditation")
    ///   - duration: Optional duration in seconds (default: 600)
    static func createTestMeditation(
        teacher: String = "Test Teacher",
        name: String = "Test Meditation",
        duration: TimeInterval = 600,
        startGongEnabled: Bool = false,
        endGongEnabled: Bool = false,
        gongSoundId: String = GongSound.defaultSoundId
    ) -> GuidedMeditation {
        let meditationId = UUID()
        return GuidedMeditation(
            id: meditationId,
            localFilePath: "\(meditationId.uuidString).mp3",
            fileName: "test.mp3",
            duration: duration,
            teacher: teacher,
            name: name,
            startGongEnabled: startGongEnabled,
            endGongEnabled: endGongEnabled,
            gongSoundId: gongSoundId
        )
    }
}
