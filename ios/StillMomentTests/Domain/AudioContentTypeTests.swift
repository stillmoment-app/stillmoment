//
//  AudioContentTypeTests.swift
//  Still Moment
//
//  shared-131: Welche vom Server gemeldeten Dateitypen der Link- und Podcast-Import annimmt
//  (identisch zu Android).
//

import XCTest
@testable import StillMoment

final class AudioContentTypeTests: XCTestCase {
    func testMp3AndM4aTypesAndGenericBinaryAreAccepted() {
        let accepted = [
            "audio/mpeg",
            "audio/mp3",
            "audio/x-mpeg",
            "audio/mpeg3",
            "audio/mp4",
            "audio/x-m4a",
            "audio/m4a",
            "application/octet-stream"
        ]
        for contentType in accepted {
            XCTAssertTrue(AudioContentType.isAccepted(contentType), contentType)
        }
    }

    func testRecordingServedAsBinaryOctetStreamIsAccepted() {
        // S3-Standardtyp, wenn beim Hochladen kein Typ gesetzt wurde (audiodharma.org, shared-132)
        XCTAssertTrue(AudioContentType.isAccepted("binary/octet-stream"))
        XCTAssertTrue(AudioContentType.isAccepted("Binary/Octet-Stream; charset=UTF-8"))
    }

    func testCaseAndParametersAfterSemicolonDoNotMatter() {
        for contentType in [
            "Audio/MPEG",
            "audio/mpeg; charset=UTF-8",
            " audio/x-m4a ;foo=bar",
            "AUDIO/MP4;codecs=mp4a"
        ] {
            XCTAssertTrue(AudioContentType.isAccepted(contentType), contentType)
        }
    }

    func testFileWithoutReportedTypeIsAccepted() {
        XCTAssertTrue(AudioContentType.isAccepted(nil))
    }

    func testEmptyReportedTypeIsRejected() {
        for contentType in ["", "   ", "; charset=UTF-8"] {
            XCTAssertFalse(AudioContentType.isAccepted(contentType), "'\(contentType)'")
        }
    }

    func testOtherAudioFormatsAndWebPagesAreRejected() {
        for contentType in ["audio/ogg", "audio/aac", "audio/wav", "text/html", "application/json"] {
            XCTAssertFalse(AudioContentType.isAccepted(contentType), contentType)
        }
    }

    func testTypesThatOnlyStartLikeAnAcceptedTypeAreRejected() {
        let lookalikes = ["audio/mpegurl", "audio/x-mpegurl", "audio/mp4a-latm", "application/octet-stream-x"]
        for contentType in lookalikes {
            XCTAssertFalse(AudioContentType.isAccepted(contentType), contentType)
        }
    }
}
