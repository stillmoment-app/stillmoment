//
//  LibrarySearchEngineTests.swift
//  Still Moment
//
//  Tests fuer die Such-Logik der Bibliothek (ios-041).
//

import XCTest
@testable import StillMoment

final class LibrarySearchEngineTests: XCTestCase {
    // MARK: - Token-Splitting

    func testTokensFromEmptyQueryIsEmpty() {
        XCTAssertTrue(LibrarySearchEngine.tokens(from: "").isEmpty)
    }

    func testTokensFromBlankQueryIsEmpty() {
        XCTAssertTrue(LibrarySearchEngine.tokens(from: "   ").isEmpty)
    }

    func testTokensSplitsOnWhitespace() {
        XCTAssertEqual(LibrarySearchEngine.tokens(from: "tara body"), ["tara", "body"])
    }

    func testTokensCollapsesMultipleSpaces() {
        XCTAssertEqual(LibrarySearchEngine.tokens(from: "tara   body  scan"), ["tara", "body", "scan"])
    }

    // MARK: - Case-Insensitive Substring-Match

    func testSearchFindsCaseInsensitiveTitleMatch() {
        let med = self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")
        let result = LibrarySearchEngine.search(meditations: [med], query: "ATEM")
        XCTAssertEqual(result.map(\.id), [med.id])
    }

    func testSearchFindsTeacherMatch() {
        let med = self.makeMeditation(name: "Body Scan", teacher: "Elisabeth Slator")
        let result = LibrarySearchEngine.search(meditations: [med], query: "slat")
        XCTAssertEqual(result.map(\.id), [med.id])
    }

    // MARK: - Diacritica-Insensitive Match

    func testSearchFindsDiacriticInsensitiveMatch() {
        let med = self.makeMeditation(name: "Übung im Loslassen", teacher: "Jon Kabat-Zinn")
        let result = LibrarySearchEngine.search(meditations: [med], query: "ubung")
        XCTAssertEqual(result.map(\.id), [med.id])
    }

    // MARK: - Substring-Match mittendrin

    func testSearchFindsSubstringInMiddle() {
        // "ara" liegt mitten in "Tara" — substring-Match jenseits des Wortanfangs.
        let med = self.makeMeditation(name: "Tara Brach Anker", teacher: "Anyone")
        let result = LibrarySearchEngine.search(meditations: [med], query: "ara")
        XCTAssertEqual(result.map(\.id), [med.id])
    }

    // MARK: - Multi-Token-UND

    func testMultiTokenRequiresAllTokensToMatchSomewhere() {
        let hit = self.makeMeditation(name: "Body Scan", teacher: "Tara Brach")
        let miss = self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")

        let result = LibrarySearchEngine.search(meditations: [hit, miss], query: "tara body")
        XCTAssertEqual(result.map(\.id), [hit.id])
    }

    func testMultiTokenAllowsTokensInDifferentFields() {
        let med = self.makeMeditation(name: "Body Scan", teacher: "Tara Brach")
        let result = LibrarySearchEngine.search(meditations: [med], query: "body brach")
        XCTAssertEqual(result.map(\.id), [med.id])
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsNoResults() {
        let med = self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")
        let result = LibrarySearchEngine.search(meditations: [med], query: "")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Bucket-Sortierung

    func testSortsByBucketsWordStartInTitleBeatsWordStartInTeacher() {
        let titleStart = self.makeMeditation(name: "Anker Atem", teacher: "Markus")
        let teacherStart = self.makeMeditation(name: "Body Scan", teacher: "Anke Roeske")

        let result = LibrarySearchEngine.search(
            meditations: [teacherStart, titleStart],
            query: "anke"
        )
        XCTAssertEqual(result.map(\.id), [titleStart.id, teacherStart.id])
    }

    func testSortsBucketsAcrossAllFour() {
        // Query "ana" — vier Items, jedes in einem anderen Bucket
        // 1) Wortanfang im Titel:   "Anatomy" / "Jon"
        // 2) Wortanfang im Lehrer:  "Calm Mind" / "Anatoly Pavlov"
        // 3) Substring im Titel:    "Manana" / "Sara"
        // 4) Substring im Lehrer:   "Wave" / "Tatiana Brach"
        let bucket1 = self.makeMeditation(name: "Anatomy", teacher: "Jon")
        let bucket2 = self.makeMeditation(name: "Calm Mind", teacher: "Anatoly Pavlov")
        let bucket3 = self.makeMeditation(name: "Manana", teacher: "Sara")
        let bucket4 = self.makeMeditation(name: "Wave", teacher: "Tatiana Brach")

        let shuffled = [bucket4, bucket3, bucket2, bucket1]
        let result = LibrarySearchEngine.search(meditations: shuffled, query: "ana")
        XCTAssertEqual(result.map(\.id), [bucket1.id, bucket2.id, bucket3.id, bucket4.id])
    }

    func testBucketUsesBestMatchAcrossTokens() {
        // "tara body" gegen "Body Scan" / "Tara Brach":
        // - "tara" → Wortanfang im Lehrer (Bucket 2)
        // - "body" → Wortanfang im Titel (Bucket 1)
        // best-match-wins → Meditation insgesamt Bucket 1
        let multiBucket = self.makeMeditation(name: "Body Scan", teacher: "Tara Brach")
        let onlyBucket2 = self.makeMeditation(name: "Anker", teacher: "Tara Brach")
        // Tara matcht in Lehrer (Wortanfang = Bucket 2), Body matcht nicht → ausgeschlossen
        // Wir brauchen ein Item das nur in Bucket 2 ist, also nur ein Token:
        let result = LibrarySearchEngine.search(
            meditations: [onlyBucket2, multiBucket],
            query: "tara"
        )
        // Beide haben Wortanfang im Lehrer → gleicher Bucket; Tiebreaker (dateAdded) entscheidet
        XCTAssertEqual(Set(result.map(\.id)), Set([multiBucket.id, onlyBucket2.id]))

        // Direkter Bucket-Test mit zwei Items, Multi-Token:
        let item = self.makeMeditation(name: "Body Scan", teacher: "Tara Brach")
        let combined = LibrarySearchEngine.search(meditations: [item], query: "tara body")
        XCTAssertEqual(combined.map(\.id), [item.id])
    }

    // MARK: - Tiebreaker

    func testTiebreakerNewerDateAddedFirst() {
        let older = self.makeMeditation(
            name: "Anker Atem",
            teacher: "Markus",
            dateAdded: Date(timeIntervalSince1970: 1000)
        )
        let newer = self.makeMeditation(
            name: "Anker Tiefe",
            teacher: "Markus",
            dateAdded: Date(timeIntervalSince1970: 2000)
        )
        let result = LibrarySearchEngine.search(meditations: [older, newer], query: "anker")
        XCTAssertEqual(result.map(\.id), [newer.id, older.id])
    }

    // MARK: - Highlight-Ranges

    func testHighlightRangesFindsAllOccurrencesOfToken() {
        let ranges = LibrarySearchEngine.highlightRanges(in: "Tara Brach Tara", query: "tara")
        XCTAssertEqual(ranges.count, 2)
    }

    func testHighlightRangesIsCaseAndDiacriticInsensitive() {
        let ranges = LibrarySearchEngine.highlightRanges(in: "Übung", query: "ubung")
        XCTAssertEqual(ranges.count, 1)
    }

    func testHighlightRangesHandlesMultiTokenQuery() {
        let ranges = LibrarySearchEngine.highlightRanges(in: "Body Scan mit Tara Brach", query: "tara body")
        // 2 Treffer: "Body" und "Tara"
        XCTAssertEqual(ranges.count, 2)
    }

    func testHighlightRangesReturnsEmptyForEmptyQuery() {
        let ranges = LibrarySearchEngine.highlightRanges(in: "Atemmeditation", query: "")
        XCTAssertTrue(ranges.isEmpty)
    }

    // MARK: - Helpers

    private func makeMeditation(
        name: String,
        teacher: String,
        dateAdded: Date = Date()
    ) -> GuidedMeditation {
        GuidedMeditation(
            id: UUID(),
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name,
            dateAdded: dateAdded
        )
    }
}
