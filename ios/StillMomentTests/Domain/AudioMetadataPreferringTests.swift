//
//  AudioMetadataPreferringTests.swift
//  Still Moment
//
//  shared-128: Vorschlaege aus dem Podcast-Verzeichnis haben Vorrang vor den ID3-Tags der Datei.
//

import XCTest
@testable import StillMoment

final class AudioMetadataPreferringTests: XCTestCase {
    private let fileMetadata = AudioMetadata(artist: "DLF", title: "ep_123", duration: 1234, album: "Feed")

    func testSuggestionsReplaceFileTags() {
        let result = self.fileMetadata.preferring(title: "Body Scan (20:34 Min.)", artist: "Deutschlandfunk Nova")

        XCTAssertEqual(result.title, "Body Scan (20:34 Min.)")
        XCTAssertEqual(result.artist, "Deutschlandfunk Nova")
        XCTAssertEqual(result.duration, 1234)
        XCTAssertEqual(result.album, "Feed")
    }

    func testMissingOrEmptySuggestionsKeepFileTags() {
        let result = self.fileMetadata.preferring(title: nil, artist: "  ")

        XCTAssertEqual(result, self.fileMetadata)
    }
}
