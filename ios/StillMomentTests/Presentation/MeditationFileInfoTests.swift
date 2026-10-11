//
//  MeditationFileInfoTests.swift
//  Still Moment
//
//  Inhalt der Datei-Info im Bearbeiten-Blatt (shared-139).
//
//  Das Layout (Dauer nie gekuerzt, Dateiname in der Mitte gekuerzt) ist im Unit-Test
//  nicht pruefbar und wird per Screenshot verifiziert. Hier wird belegt, *was* die
//  Datei-Info anzeigt und vorliest.
//

import XCTest
@testable import StillMoment

final class MeditationFileInfoTests: XCTestCase {
    private let longFileName =
        "20260504-David_Lorey-IMC-dharmette_the_heart_of_practice_1_of_5_this_and_that.mp3"

    func testFileInfoShowsFileNameAndDuration() {
        // Given: audiodharma talk 25402 (19:52)
        let meditation = self.makeMeditation(fileName: self.longFileName, duration: 1192)

        // When
        let info = MeditationFileInfo(meditation: meditation)

        // Then
        XCTAssertEqual(info.fileName, self.longFileName)
        XCTAssertEqual(info.duration, "19:52")
    }

    func testTrimmedMeditationShowsFullFileLength() {
        // Given: 10:00 file trimmed to 8:30
        let meditation = self.makeMeditation(
            fileName: "short.mp3",
            duration: 600,
            trimStart: 30,
            trimEnd: 540
        )

        // When
        let info = MeditationFileInfo(meditation: meditation)

        // Then: the file info names the real file length, not the trimmed duration
        XCTAssertEqual(info.duration, "10:00")
    }

    func testVoiceOverReadsFullFileNameAndDurationTogether() {
        // Given: a name long enough to be truncated on screen
        let meditation = self.makeMeditation(fileName: self.longFileName, duration: 1192)

        // When
        let label = MeditationFileInfo(meditation: meditation).accessibilityLabel

        // Then: VoiceOver hears the untruncated name and the duration in one element
        XCTAssertTrue(label.hasPrefix(self.longFileName), "Name fehlt oder gekuerzt: \(label)")
        XCTAssertTrue(label.hasSuffix("19:52"), "Dauer fehlt: \(label)")
    }

    // MARK: - Helpers

    private func makeMeditation(
        fileName: String,
        duration: TimeInterval,
        trimStart: TimeInterval? = nil,
        trimEnd: TimeInterval? = nil
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: fileName,
            fileName: fileName,
            duration: duration,
            teacher: "David Lorey",
            name: "This and That",
            trimStart: trimStart,
            trimEnd: trimEnd
        )
    }
}
