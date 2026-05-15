//
//  SearchHistoryTests.swift
//  Still Moment
//
//  Tests fuer die pure prepend-Logik der Suchhistorie (ios-041).
//

import XCTest
@testable import StillMoment

final class SearchHistoryTests: XCTestCase {
    // MARK: - Prepend

    func testPrependAddsTermToEmptyHistory() {
        let result = SearchHistory.prepend(history: [], term: "Tara", limit: 6)
        XCTAssertEqual(result, ["Tara"])
    }

    func testPrependPutsNewestOnTop() {
        let result = SearchHistory.prepend(history: ["Atem"], term: "Tara", limit: 6)
        XCTAssertEqual(result, ["Tara", "Atem"])
    }

    // MARK: - Deduplication

    func testPrependMovesDuplicateToTop() {
        let result = SearchHistory.prepend(history: ["Body", "Tara", "Atem"], term: "Tara", limit: 6)
        XCTAssertEqual(result, ["Tara", "Body", "Atem"])
    }

    func testPrependDeduplicatesCaseInsensitively() {
        let result = SearchHistory.prepend(history: ["Atem", "Tara"], term: "ATEM", limit: 6)
        XCTAssertEqual(result, ["ATEM", "Tara"])
    }

    func testPrependDeduplicatesDiacriticInsensitively() {
        let result = SearchHistory.prepend(history: ["Übung", "Tara"], term: "ubung", limit: 6)
        XCTAssertEqual(result, ["ubung", "Tara"])
    }

    // MARK: - FIFO-Cap

    func testPrependEnforcesLimitDroppingOldest() {
        let result = SearchHistory.prepend(
            history: ["F", "E", "D", "C", "B", "A"],
            term: "G",
            limit: 6
        )
        XCTAssertEqual(result, ["G", "F", "E", "D", "C", "B"])
    }

    // MARK: - Empty / Whitespace

    func testPrependIgnoresEmptyTerm() {
        let result = SearchHistory.prepend(history: ["Tara"], term: "", limit: 6)
        XCTAssertEqual(result, ["Tara"])
    }

    func testPrependIgnoresWhitespaceOnlyTerm() {
        let result = SearchHistory.prepend(history: ["Tara"], term: "   ", limit: 6)
        XCTAssertEqual(result, ["Tara"])
    }

    func testPrependTrimsTermWhitespace() {
        let result = SearchHistory.prepend(history: [], term: "  Atem  ", limit: 6)
        XCTAssertEqual(result, ["Atem"])
    }
}
