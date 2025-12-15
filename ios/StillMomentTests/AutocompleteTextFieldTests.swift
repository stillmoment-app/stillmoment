//
//  AutocompleteTextFieldTests.swift
//  Still Moment
//
//  Unit Tests for AutocompleteTextField filter logic
//

import XCTest
@testable import StillMoment

final class AutocompleteTextFieldTests: XCTestCase {
    // MARK: - Filter Logic Tests

    func testEmptyTextReturnsNoSuggestions() {
        // Given
        let suggestions = ["Alice", "Bob", "Charlie"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testMatchingTextReturnsFilteredSuggestions() {
        // Given
        let suggestions = ["Alice", "Albert", "Bob", "Charlie"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "Al")

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("Alice"))
        XCTAssertTrue(result.contains("Albert"))
        XCTAssertFalse(result.contains("Bob"))
    }

    func testExactMatchReturnsNoSuggestions() {
        // Given - Prevents showing "Alice" when user typed exactly "Alice"
        let suggestions = ["Alice", "Bob"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "Alice")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testCaseInsensitiveMatching() {
        // Given
        let suggestions = ["Alice", "ALBERT", "alice smith"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "ali")

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("Alice"))
        XCTAssertTrue(result.contains("alice smith"))
    }

    func testMaximumFiveSuggestionsReturned() {
        // Given - More than 5 matching suggestions
        let suggestions = [
            "Alice A",
            "Alice B",
            "Alice C",
            "Alice D",
            "Alice E",
            "Alice F",
            "Alice G"
        ]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "Alice")

        // Then
        XCTAssertEqual(result.count, 5)
    }

    func testNoMatchReturnsEmpty() {
        // Given
        let suggestions = ["Alice", "Bob", "Charlie"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "xyz")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testContainsMatchingNotJustPrefix() {
        // Given - Should match "contains" not just "starts with"
        let suggestions = ["Alice Smith", "Bob Alice", "Charlie"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "Alice")

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("Alice Smith"))
        XCTAssertTrue(result.contains("Bob Alice"))
    }

    func testEmptySuggestionsReturnsEmpty() {
        // Given
        let suggestions: [String] = []

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "test")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testExactMatchCaseInsensitive() {
        // Given - "alice" should not match "Alice" as exact match
        let suggestions = ["Alice", "Bob"]

        // When
        let result = AutocompleteTextField.filterSuggestions(suggestions, for: "alice")

        // Then - Should be empty because "alice" == "Alice" case-insensitively
        XCTAssertTrue(result.isEmpty)
    }
}
