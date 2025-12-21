//
//  MockAudioMetadataService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockAudioMetadataService: AudioMetadataServiceProtocol {
    var extractedMetadata: AudioMetadata?
    var extractShouldThrow = false

    func extractMetadata(from url: URL) async throws -> AudioMetadata {
        if self.extractShouldThrow {
            throw AudioMetadataError.invalidAudioFile
        }
        let metadata = AudioMetadata(
            artist: "Test Artist",
            title: "Test Title",
            duration: 600
        )
        self.extractedMetadata = metadata
        return metadata
    }
}
