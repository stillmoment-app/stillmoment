//
//  ImportPrefillTests.swift
//  Still Moment
//
//  Domain-Tests fuer den Prefill-Service beim Meditation-Import (ios-043).
//

import XCTest
@testable import StillMoment

final class ImportPrefillTests: XCTestCase {
    // MARK: - Sanitize-Funktion

    func testSanitizeNilAndWhitespaceOnlyReturnNil() {
        XCTAssertNil(ImportPrefill.sanitize(nil))
        XCTAssertNil(ImportPrefill.sanitize("   "))
        XCTAssertNil(ImportPrefill.sanitize("\t\n"))
    }

    func testSanitizeDenyListUnknownArtistVariantsReturnNil() {
        XCTAssertNil(ImportPrefill.sanitize("Unknown Artist"))
        XCTAssertNil(ImportPrefill.sanitize("unknown_artist"))
        XCTAssertNil(ImportPrefill.sanitize("unknown-artist"))
        XCTAssertNil(ImportPrefill.sanitize("UNKNOWN ARTIST"))
        XCTAssertNil(ImportPrefill.sanitize("Unknown   Artist"))
    }

    func testSanitizeDenyListAdditionalPlaceholdersReturnNil() {
        XCTAssertNil(ImportPrefill.sanitize("Untitled"))
        XCTAssertNil(ImportPrefill.sanitize("audio"))
        XCTAssertNil(ImportPrefill.sanitize("recording"))
        XCTAssertNil(ImportPrefill.sanitize("voice memo"))
        XCTAssertNil(ImportPrefill.sanitize("voice_memo"))
    }

    func testSanitizePureTrackNumberingReturnsNil() {
        XCTAssertNil(ImportPrefill.sanitize("Track 01"))
        XCTAssertNil(ImportPrefill.sanitize("01"))
        XCTAssertNil(ImportPrefill.sanitize("1"))
        XCTAssertNil(ImportPrefill.sanitize("track 03"))
        XCTAssertNil(ImportPrefill.sanitize("track03"))
    }

    func testSanitizeCleanValueIsReturnedUnchanged() {
        XCTAssertEqual(ImportPrefill.sanitize("Tara Brach"), "Tara Brach")
    }

    func testSanitizeTrimsOuterWhitespaceButLeavesContentIntact() {
        XCTAssertEqual(ImportPrefill.sanitize("  Body Scan  "), "Body Scan")
    }

    // MARK: - Filename-Preprocessing

    func testPreprocessRemovesTrackPrefixAndNormalizesSeparators() {
        XCTAssertEqual(ImportPrefill.preprocessFilename("01-body-scan.mp3"), "body scan")
    }

    func testPreprocessKeepsLowercaseCasingVerbatim() {
        XCTAssertEqual(ImportPrefill.preprocessFilename("Bodyscan.mp3"), "Bodyscan")
    }

    func testPreprocessKeepsGermanPrepositionsLowercase() {
        XCTAssertEqual(ImportPrefill.preprocessFilename("meditation-im-sitzen.mp3"), "meditation im sitzen")
    }

    func testPreprocessKeepsUppercaseAcronymsIntact() {
        XCTAssertEqual(
            ImportPrefill.preprocessFilename("Anleitung-Bodyscan-Deutsch-MBSR.mp3"),
            "Anleitung Bodyscan Deutsch MBSR"
        )
    }

    func testPreprocessDoesNotApplyTitleCaseTransformation() {
        // Mixed-Casing-Input bleibt 1:1 erhalten — keine kuenstliche Title-Case-Normalisierung.
        XCTAssertEqual(ImportPrefill.preprocessFilename("MORNING-meditation.mp3"), "MORNING meditation")
    }

    // MARK: - Garbage-Detection

    func testIsGarbageDetectsUUID() {
        XCTAssertTrue(ImportPrefill.isGarbageFilename("d067c0ea-2c04-b934-1e04-94b2dc2f13dd"))
    }

    func testIsGarbageDetectsLongTokenWithoutSeparators() {
        XCTAssertTrue(ImportPrefill.isGarbageFilename("thisistheverylongunbrokenfilename"))
        XCTAssertTrue(ImportPrefill.isGarbageFilename("abc123def456ghi789jklmnop")) // pragma: allowlist secret
    }

    func testIsGarbageDetectsEmptyAfterPreprocessing() {
        XCTAssertTrue(ImportPrefill.isGarbageFilename(""))
    }

    func testIsGarbageAcceptsShortReadableFilename() {
        XCTAssertFalse(ImportPrefill.isGarbageFilename("bodyscan"))
    }

    func testIsGarbageAcceptsMultiTokenFilename() {
        XCTAssertFalse(ImportPrefill.isGarbageFilename("body scan"))
    }

    // MARK: - Teacher-Kaskade

    func testTeacherFromID3ArtistWins() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: "Tara Brach", title: nil),
            fileName: "bodyscan.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
    }

    func testTeacherFromID3UnknownArtistIsDropped() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: "Unknown Artist", title: nil),
            fileName: "bodyscan.mp3",
            knownTeachers: []
        )
        XCTAssertNil(prefill.teacher)
    }

    func testTeacherFromFilenameMatchedAgainstKnownTeachers() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "bodyscan-tara_brach.mp3",
            knownTeachers: ["Tara Brach"]
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
    }

    func testTeacherIgnoresUnknownArtistInsideKnownTeachers() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "unknown_artist-foo.mp3",
            knownTeachers: ["Unknown Artist", "Tara Brach"]
        )
        XCTAssertNil(prefill.teacher)
    }

    func testTeacherLongestKnownTeacherWinsBeforeShorterPrefix() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "tara-brach-bodyscan.mp3",
            knownTeachers: ["Tara", "Tara Brach"]
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
    }

    func testTeacherShortSingleWordKnownTeacherIsNotMatched() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "tara-bodyscan.mp3",
            knownTeachers: ["Tara"]
        )
        XCTAssertNil(prefill.teacher)
    }

    func testTeacherFallsThroughToNilWhenKnownTeachersEmpty() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "bodyscan-tara_brach.mp3",
            knownTeachers: []
        )
        XCTAssertNil(prefill.teacher)
    }

    // MARK: - Title-Kaskade

    func testTitleFromID3WinsWhenSanitized() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: "Body Scan"),
            fileName: "01-irrelevant.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.name, "Body Scan")
    }

    func testTitleFallsBackToFilenameWhenID3TitleIsUntitled() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: "Untitled"),
            fileName: "Anleitung-Bodyscan-Deutsch-MBSR.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.name, "Anleitung Bodyscan Deutsch MBSR")
    }

    func testTitleFromFilenameRespectsVerbatimCasing() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "meditation-im-sitzen.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.name, "meditation im sitzen")
    }

    func testTitleRemovesTeacherSubstringWhenTeacherMatchedFromFilename() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "bodyscan-tara_brach.mp3",
            knownTeachers: ["Tara Brach"]
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
        XCTAssertEqual(prefill.name, "bodyscan")
    }

    func testTitleRemovesTeacherSubstringEvenIfTeacherCameFromID3() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: "Tara Brach", title: nil),
            fileName: "bodyscan-tara_brach.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
        XCTAssertEqual(prefill.name, "bodyscan")
    }

    func testTitleKeepsFullFilenameWhenTeacherFromID3IsNotInFilename() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: "Tara Brach", title: nil),
            fileName: "morning-meditation.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.teacher, "Tara Brach")
        XCTAssertEqual(prefill.name, "morning meditation")
    }

    func testTitleNilForUUIDFilenameWithoutID3() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3",
            knownTeachers: []
        )
        XCTAssertNil(prefill.name)
    }

    func testTitleNilForServerDefaultFilenameAudioMp3() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "audio.mp3",
            knownTeachers: []
        )
        XCTAssertNil(prefill.name)
    }

    func testTitleStripsTrackPrefixFromFilename() {
        let prefill = ImportPrefill.compute(
            metadata: self.meta(artist: nil, title: nil),
            fileName: "01-body-scan.mp3",
            knownTeachers: []
        )
        XCTAssertEqual(prefill.name, "body scan")
    }

    // MARK: - Helpers

    private func meta(artist: String?, title: String?) -> AudioMetadata {
        AudioMetadata(artist: artist, title: title, duration: 600)
    }
}
