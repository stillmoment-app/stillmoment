//
//  MeditationSourceRepositoryTests.swift
//  Still Moment
//
//  Tests for the JSON-driven Content Guide source catalog.
//

import XCTest
@testable import StillMoment

final class MeditationSourceRepositoryTests: XCTestCase {
    // MARK: Internal

    // MARK: - Decoding

    func testDeCatalogHasExpectedEntries() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        XCTAssertEqual(catalog.sourcesByLanguage["de"]?.count, 2)
    }

    func testEnCatalogHasExpectedEntries() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        XCTAssertEqual(catalog.sourcesByLanguage["en"]?.count, 1)
    }

    func testEntryWithOfferPreservesIt() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let mangold = catalog.sourcesByLanguage["de"]?.first { $0.id == "mangold" }
        XCTAssertEqual(mangold?.name, "Jörg Mangold")
        XCTAssertEqual(mangold?.offer, "Achtsamkeit & Selbstmitgefühl")
    }

    func testNullOfferBecomesNilInDomain() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let braehler = catalog.sourcesByLanguage["de"]?.first { $0.id == "braehler" }
        XCTAssertNotNil(braehler)
        XCTAssertNil(braehler?.offer)
    }

    func testBlankOfferBecomesNilInDomain() throws {
        let json = """
            {
              "en": [
                {
                  "id": "x",
                  "name": "X",
                  "offer": "   ",
                  "description": "d",
                  "host": "h",
                  "url": "https://example.com/"
                }
              ]
            }
            """
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(json.utf8))
        XCTAssertNil(catalog.sourcesByLanguage["en"]?.first?.offer)
    }

    func testNonHttpUrlIsRejected() throws {
        let json = """
            {
              "en": [
                {
                  "id": "bad",
                  "name": "Bad",
                  "offer": null,
                  "description": "d",
                  "host": "h",
                  "url": "javascript:alert(1)"
                },
                {
                  "id": "good",
                  "name": "Good",
                  "offer": null,
                  "description": "d",
                  "host": "h",
                  "url": "https://example.com/"
                }
              ]
            }
            """
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(json.utf8))
        XCTAssertEqual(catalog.sourcesByLanguage["en"]?.map(\.id), ["good"])
    }

    func testParsedEntriesExposeAllFields() throws {
        let catalog = try MeditationSourceRepository.decodeCatalog(from: Data(self.validJSON.utf8))
        let tara = try XCTUnwrap(catalog.sourcesByLanguage["en"]?.first)
        XCTAssertEqual(tara.name, "Tara Brach")
        XCTAssertEqual(tara.description, "Guided meditations, RAIN practice.")
        XCTAssertEqual(tara.host, "tarabrach.com")
        XCTAssertEqual(tara.url.absoluteString, "https://example.com/tara")
    }

    // MARK: - Shipped catalog (meditation_sources.json in the app bundle)

    func testShippedCatalogOffersFourGermanAndFourEnglishSources() {
        let catalog = MeditationSourceRepository(bundle: .main).catalog()

        XCTAssertEqual(
            catalog.sourcesByLanguage["de"]?.map(\.name),
            ["Kirsten Tofahrn", "Christine Brähler", "Jörg Mangold", "Melissa Gein"]
        )
        XCTAssertEqual(
            catalog.sourcesByLanguage["en"]?.map(\.name),
            ["Audio Dharma", "Tara Brach", "UCLA Mindful", "Free Mindfulness Project"]
        )
    }

    func testShippedCatalogNamesTheOfferOnlyWhereItHasItsOwnName() {
        let sources = self.shippedSources()
        let offers = Dictionary(uniqueKeysWithValues: sources.map { ($0.name, $0.offer) })

        XCTAssertEqual(offers["Kirsten Tofahrn"], "Zentrum für Achtsamkeit Köln")
        XCTAssertEqual(offers["Christine Brähler"], .some(nil))
        XCTAssertEqual(offers["Jörg Mangold"], "Achtsamkeit & Selbstmitgefühl")
        XCTAssertEqual(offers["Melissa Gein"], "Podcast \u{201E}Einfach meditieren\u{201C}")
        XCTAssertEqual(offers["Tara Brach"], .some(nil))
        XCTAssertEqual(offers["Audio Dharma"], "Insight Meditation Center")
        XCTAssertEqual(offers["UCLA Mindful"], "UCLA Health")
        XCTAssertEqual(offers["Free Mindfulness Project"], .some(nil))
    }

    func testMelissaGeinLeadsToHerPodcastInApplePodcasts() throws {
        let gein = try XCTUnwrap(self.shippedSources().first { $0.name == "Melissa Gein" })

        XCTAssertEqual(
            gein.url.absoluteString,
            "https://podcasts.apple.com/de/podcast/einfach-meditieren-einfach-achtsam-leben/id1588419775"
        )
        XCTAssertEqual(gein.host, "podcasts.apple.com")
    }

    func testNoShippedDescriptionNamesThePersonWithVon() {
        for source in self.shippedSources() {
            XCTAssertFalse(source.description.contains("Von "), "\(source.id): \(source.description)")
        }
    }

    // MARK: Private

    private let validJSON = """
        {
          "de": [
            {
              "id": "mangold",
              "name": "Jörg Mangold",
              "offer": "Achtsamkeit & Selbstmitgefühl",
              "description": "MBSR, MSC, Körperscans.",
              "host": "example.de",
              "url": "https://example.de/mangold"
            },
            {
              "id": "braehler",
              "name": "Christine Brähler",
              "offer": null,
              "description": "Selbstmitgefühl mit Tiefe.",
              "host": "example.de",
              "url": "https://example.de/braehler"
            }
          ],
          "en": [
            {
              "id": "tara-brach",
              "name": "Tara Brach",
              "offer": null,
              "description": "Guided meditations, RAIN practice.",
              "host": "tarabrach.com",
              "url": "https://example.com/tara"
            }
          ]
        }
        """

    private func shippedSources() -> [MeditationSource] {
        MeditationSourceRepository(bundle: .main).catalog().sourcesByLanguage.values.flatMap { $0 }
    }
}
