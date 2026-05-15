//
//  MockAudioMetadataService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockAudioMetadataService: AudioMetadataServiceProtocol {
    var extractedMetadata: AudioMetadata?
    var extractShouldThrow = false

    /// Override the default mock metadata returned by `extractMetadata`. If `nil`,
    /// a "Test Artist / Test Title / 600s" fixture is returned.
    var fixedMetadata: AudioMetadata?

    func extractMetadata(from url: URL) async throws -> AudioMetadata {
        if self.extractShouldThrow {
            throw AudioMetadataError.invalidAudioFile
        }
        let metadata = self.fixedMetadata ?? AudioMetadata(
            artist: "Test Artist",
            title: "Test Title",
            duration: 600
        )
        self.extractedMetadata = metadata
        return metadata
    }
}
