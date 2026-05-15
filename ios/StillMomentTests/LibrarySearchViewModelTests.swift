//
//  LibrarySearchViewModelTests.swift
//  Still Moment
//
//  Tests fuer die Such-Erweiterung des Library-ViewModels (ios-041).
//

import XCTest
@testable import StillMoment

@MainActor
final class LibrarySearchViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationsListViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockHistoryStore: MockSearchHistoryStore!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockHistoryStore = MockSearchHistoryStore()
        self.sut = self.makeSUT()
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistoryStore = nil
        self.mockMeditationService = nil
        super.tearDown()
    }

    // MARK: - State-Uebergaenge

    func testInitialStateIsIdle() {
        XCTAssertEqual(self.sut.searchState, .idle)
        XCTAssertEqual(self.sut.searchQuery, "")
        XCTAssertFalse(self.sut.isSearching)
    }

    func testFocusedWithEmptyQueryShowsHistoryState() {
        self.sut.isSearching = true
        XCTAssertEqual(self.sut.searchState, .history)
    }

    func testQueryWithMatchesShowsResultsState() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.isSearching = true
        self.sut.searchQuery = "atem"

        XCTAssertEqual(self.sut.searchState, .results)
        XCTAssertEqual(self.sut.searchResults.count, 1)
    }

    func testQueryWithoutMatchesShowsEmptyState() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.isSearching = true
        self.sut.searchQuery = "xyz123"

        XCTAssertEqual(self.sut.searchState, .empty)
        XCTAssertTrue(self.sut.searchResults.isEmpty)
    }

    // MARK: - Historie laden

    func testInitLoadsHistoryFromStore() {
        self.mockHistoryStore.storedHistory = ["Atem", "Tara"]
        let viewModel = self.makeSUT()
        XCTAssertEqual(viewModel.searchHistory, ["Atem", "Tara"])
    }

    // MARK: - Submit

    func testSubmitSearchAddsTermToHistoryWhenResultsExist() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.searchQuery = "atem"

        self.sut.submitSearch()

        XCTAssertEqual(self.sut.searchHistory, ["atem"])
        XCTAssertEqual(self.mockHistoryStore.storedHistory, ["atem"])
    }

    func testSubmitSearchDoesNotAddTermWhenNoResults() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.searchQuery = "xyz123"

        self.sut.submitSearch()

        XCTAssertTrue(self.sut.searchHistory.isEmpty)
        XCTAssertTrue(self.mockHistoryStore.storedHistory.isEmpty)
    }

    // MARK: - Tap-auf-Treffer commit + reset

    func testRecordSearchCommittedByOpeningAddsTermToHistory() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.searchQuery = "atem"

        self.sut.recordSearchCommittedByOpening()

        XCTAssertEqual(self.sut.searchHistory, ["atem"])
    }

    func testRecordSearchCommittedByOpeningResetsQuery() {
        self.sut.meditations = [self.makeMeditation(name: "Atemmeditation", teacher: "Tara Brach")]
        self.sut.searchQuery = "atem"

        self.sut.recordSearchCommittedByOpening()

        XCTAssertEqual(self.sut.searchQuery, "")
        XCTAssertFalse(self.sut.isSearching)
    }

    // MARK: - History-Tap

    func testSelectHistoryEntrySetsQuery() {
        self.sut.searchHistory = ["Tara"]

        self.sut.selectHistoryEntry("Tara")

        XCTAssertEqual(self.sut.searchQuery, "Tara")
    }

    // MARK: - Clear

    func testClearHistoryEmptiesHistoryAndPersistsEmpty() {
        self.sut.searchHistory = ["Tara", "Atem"]

        self.sut.clearHistory()

        XCTAssertTrue(self.sut.searchHistory.isEmpty)
        XCTAssertTrue(self.mockHistoryStore.storedHistory.isEmpty)
    }

    // MARK: - Reset

    func testResetSearchClearsQueryAndSearchingFlag() {
        self.sut.searchQuery = "atem"
        self.sut.isSearching = true

        self.sut.resetSearch()

        XCTAssertEqual(self.sut.searchQuery, "")
        XCTAssertFalse(self.sut.isSearching)
    }

    func testResetSearchKeepsHistory() {
        self.sut.searchHistory = ["Atem"]
        self.sut.searchQuery = "tara"
        self.sut.isSearching = true

        self.sut.resetSearch()

        XCTAssertEqual(self.sut.searchHistory, ["Atem"])
    }

    // MARK: - Helpers

    private func makeSUT() -> GuidedMeditationsListViewModel {
        GuidedMeditationsListViewModel(
            meditationService: self.mockMeditationService,
            searchHistoryStore: self.mockHistoryStore
        )
    }

    private func makeMeditation(name: String, teacher: String) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name
        )
    }
}
