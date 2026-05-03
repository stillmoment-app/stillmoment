//
//  MeditationSourceRepositoryTests.swift
//  Still Moment
//
//  Tests for the JSON-driven Content Guide source catalog.
//

import XCTest
@testable import StillMoment

final class MeditationSourceRepositoryTests: XCTestCase {
    private let validJSON = """
        {
          "de": [
            {
              "id": "mangold",
              "name": "Achtsamkeit & Selbstmitgefühl",
              "author": "Jörg Mangold",
              "description": "MBSR, MSC, Körperscans.",
              "host": "podcast",
              "url": "https://example.de/mangold"
            },
            {
              "id": "koeln",
              "name": "Zentrum für Achtsamkeit Köln",
              "author": null,
              "description": "MBSR Body Scan, Sitzmeditation.",
              "host": "achtsamkeit-koeln.de",
              "url": "https://example.de/koeln"
            }
          ],
          "en": [
            {
              "id": "tara-brach",
              "name": "Tara Brach",
              "author": null,
              "description": "Guided meditations, RAIN practice.",
              "host": "tarabrach.com",
              "url": "https://example.com/tara"
            }
          ]
        }
        """

    func testDeCatalogHasExpectedEntries() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        XCTAssertEqual(catalog["de"]?.count, 2)
    }

    func testEnCatalogHasExpectedEntries() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        XCTAssertEqual(catalog["en"]?.count, 1)
    }

    func testDeAndEnListsAreIndependent() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let deIds = Set((catalog["de"] ?? []).map(\.id))
        let enIds = Set((catalog["en"] ?? []).map(\.id))
        XCTAssertTrue(deIds.isDisjoint(with: enIds))
    }

    func testEntryWithAuthorPreservesIt() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let mangold = catalog["de"]?.first { $0.id == "mangold" }
        XCTAssertEqual(mangold?.author, "Jörg Mangold")
    }

    func testNullAuthorBecomesNilInDomain() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let koeln = catalog["de"]?.first { $0.id == "koeln" }
        XCTAssertNotNil(koeln)
        XCTAssertNil(koeln?.author)
    }

    func testEmptyAuthorBecomesNilInDomain() throws {
        let json = """
            {
              "en": [
                {
                  "id": "x",
                  "name": "X",
                  "author": "   ",
                  "description": "d",
                  "host": "h",
                  "url": "https://example.com/"
                }
              ]
            }
            """
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(json.utf8))
        XCTAssertNil(catalog["en"]?.first?.author)
    }

    func testNonHttpUrlIsRejected() throws {
        let json = """
            {
              "en": [
                {
                  "id": "bad",
                  "name": "Bad",
                  "author": null,
                  "description": "d",
                  "host": "h",
                  "url": "javascript:alert(1)"
                },
                {
                  "id": "good",
                  "name": "Good",
                  "author": null,
                  "description": "d",
                  "host": "h",
                  "url": "https://example.com/"
                }
              ]
            }
            """
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(json.utf8))
        XCTAssertEqual(catalog["en"]?.count, 1)
        XCTAssertEqual(catalog["en"]?.first?.id, "good")
    }

    func testParsedEntriesExposeAllFields() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let tara = try XCTUnwrap(catalog["en"]?.first)
        XCTAssertEqual(tara.name, "Tara Brach")
        XCTAssertEqual(tara.description, "Guided meditations, RAIN practice.")
        XCTAssertEqual(tara.host, "tarabrach.com")
        XCTAssertEqual(tara.url.absoluteString, "https://example.com/tara")
    }

    func testRepositoryFallsBackToEnglishForUnknownLanguage() {
        let repository = StubMeditationSourceRepository(
            catalog: ["en": [self.makeSource(id: "fallback")]]
        )
        XCTAssertEqual(repository.sources(for: "fr").map(\.id), ["fallback"])
    }

    func testRepositoryReturnsEmptyWhenNoEntries() {
        let repository = StubMeditationSourceRepository(catalog: [:])
        XCTAssertTrue(repository.sources(for: "en").isEmpty)
    }

    // MARK: Helpers

    private func makeSource(id: String) -> MeditationSource {
        MeditationSource(
            id: id,
            name: id,
            author: nil,
            description: "desc",
            host: "h",
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://example.com/")!
        )
    }
}

private struct StubMeditationSourceRepository: MeditationSourceRepositoryProtocol {
    let catalog: [String: [MeditationSource]]

    func sources(for languageCode: String) -> [MeditationSource] {
        self.catalog[languageCode] ?? self.catalog["en"] ?? []
    }
}
