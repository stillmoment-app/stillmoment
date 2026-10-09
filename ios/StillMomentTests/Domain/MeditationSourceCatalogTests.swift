//
//  MeditationSourceCatalogTests.swift
//  Still Moment
//
//  shared-137: Quellen der eigenen Sprache zuerst, alle anderen Sprachen darunter.
//

import XCTest
@testable import StillMoment

final class MeditationSourceCatalogTests: XCTestCase {
    // MARK: Internal

    func testGermanUserSeesGermanSourcesFirstThenEnglish() {
        let catalog = self.makeCatalog(["de": ["koeln"], "en": ["tara-brach"]])

        let groups = catalog.groups(ownLanguageCode: "de", displayName: self.englishNames)

        XCTAssertEqual(groups.map(\.languageCode), ["de", "en"])
    }

    func testEnglishUserSeesEnglishSourcesFirstThenGerman() {
        let catalog = self.makeCatalog(["de": ["koeln"], "en": ["tara-brach"]])

        let groups = catalog.groups(ownLanguageCode: "en", displayName: self.englishNames)

        XCTAssertEqual(groups.map(\.languageCode), ["en", "de"])
    }

    func testUserWithLanguageWithoutSourcesSeesEnglishFirst() {
        let catalog = self.makeCatalog(["de": ["koeln"], "en": ["tara-brach"]])

        let groups = catalog.groups(ownLanguageCode: "fr", displayName: self.englishNames)

        XCTAssertEqual(groups.map(\.languageCode), ["en", "de"])
    }

    func testOtherLanguagesFollowEnglishAlphabeticallyByDisplayedName() {
        let catalog = self.makeCatalog([
            "de": ["koeln"],
            "en": ["tara-brach"],
            "es": ["espanol"],
            "fr": ["francais"]
        ])
        // Displayed names chosen so that code order and name order differ.
        let names = ["de": "Zulu", "en": "English", "es": "Alpha", "fr": "Mike"]

        let groups = catalog.groups(ownLanguageCode: "fr") { names[$0] ?? $0 }

        XCTAssertEqual(groups.map(\.languageCode), ["fr", "en", "es", "de"])
    }

    func testSourcesKeepTheirOrderWithinALanguage() {
        let catalog = self.makeCatalog([
            "en": ["audio-dharma", "tara-brach", "ucla-mindful", "free-mindfulness"]
        ])

        let groups = catalog.groups(ownLanguageCode: "en", displayName: self.englishNames)

        XCTAssertEqual(
            groups.first?.sources.map(\.id),
            ["audio-dharma", "tara-brach", "ucla-mindful", "free-mindfulness"]
        )
    }

    func testLanguagesWithoutSourcesAreLeftOut() {
        let catalog = self.makeCatalog(["de": [], "en": ["tara-brach"]])

        let groups = catalog.groups(ownLanguageCode: "en", displayName: self.englishNames)

        XCTAssertEqual(groups.map(\.languageCode), ["en"])
    }

    func testEmptyCatalogShowsNoGroups() {
        let catalog = MeditationSourceCatalog(sourcesByLanguage: [:])

        XCTAssertTrue(catalog.groups(ownLanguageCode: "de", displayName: self.englishNames).isEmpty)
    }

    // MARK: Private

    private func englishNames(_ code: String) -> String {
        ["de": "German", "en": "English", "es": "Spanish", "fr": "French"][code] ?? code
    }

    private func makeCatalog(_ idsByLanguage: [String: [String]]) -> MeditationSourceCatalog {
        MeditationSourceCatalog(
            sourcesByLanguage: idsByLanguage.mapValues { ids in ids.map(self.makeSource) }
        )
    }

    private func makeSource(id: String) -> MeditationSource {
        MeditationSource(
            id: id,
            name: id,
            offer: nil,
            description: "desc",
            host: "example.com",
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://example.com/\(id)")!
        )
    }
}
