//
//  LibraryDurationFilterViewModelTests.swift
//  Still Moment
//
//  Tests fuer das Zusammenspiel von Dauer-Filter und Suche (shared-081).
//

import XCTest
@testable import StillMoment

@MainActor
final class LibraryDurationFilterViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationsListViewModel!

    override func setUp() {
        super.setUp()
        self.sut = GuidedMeditationsListViewModel(
            meditationService: MockGuidedMeditationService(),
            searchHistoryStore: MockSearchHistoryStore()
        )
        self.sut.meditations = self.makeLibrary()
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Einzelauswahl und Ruecksprung auf `Alle`

    func testInitiallyNoFilterIsActiveAndTheListStaysGrouped() {
        XCTAssertEqual(self.sut.durationFilter, .all)
        XCTAssertFalse(self.sut.isFilterActive)
        XCTAssertEqual(self.sut.searchState, .idle)
    }

    func testSelectingStepActivatesItAndFlattensTheList() {
        self.sut.selectDurationFilter(.from5To15)

        XCTAssertEqual(self.sut.durationFilter, .from5To15)
        XCTAssertTrue(self.sut.isFilterActive)
        XCTAssertEqual(self.sut.searchState, .filtered)
    }

    func testTappingTheActiveStepReturnsToAllAndRegroupsTheList() {
        self.sut.selectDurationFilter(.from5To15)

        self.sut.selectDurationFilter(.from5To15)

        XCTAssertEqual(self.sut.durationFilter, .all)
        XCTAssertEqual(self.sut.searchState, .idle)
    }

    func testSelectingAnotherStepReplacesTheActiveOne() {
        self.sut.selectDurationFilter(.from5To15)

        self.sut.selectDurationFilter(.over30)

        XCTAssertEqual(self.sut.durationFilter, .over30)
    }

    func testTappingAnUnavailableStepLeavesTheFilterUnchanged() {
        // Bibliothek ohne Meditation unter 5 Minuten.
        self.sut.meditations = [self.makeMeditation(name: "Body Scan", teacher: "Sarah", seconds: 942)]

        self.sut.selectDurationFilter(.upTo5)

        XCTAssertEqual(self.sut.durationFilter, .all)
    }

    // MARK: - Wirkung auf die Liste

    func testFlatListWithoutSearchFollowsTheGroupedOrder() {
        self.sut.selectDurationFilter(.from5To15)

        // Reihenfolge wie in der gruppierten Ansicht, nur ohne Ueberschriften:
        // Anna Berg (nichts in dieser Stufe), Sarah Kornfield, Tara Goldstein.
        XCTAssertEqual(self.sut.visibleMeditations.map(\.name), ["Mindful Breathing", "Loving Kindness"])
    }

    func testCountLineComparesVisibleAgainstWholeLibrary() {
        self.sut.selectDurationFilter(.from5To15)

        XCTAssertEqual(self.sut.visibleMeditations.count, 2)
        XCTAssertEqual(self.sut.meditations.count, 6)
    }

    func testWithoutFilterEveryMeditationStaysVisible() {
        XCTAssertEqual(self.sut.visibleMeditations.count, 6)
    }

    // MARK: - Zusammenspiel mit der Suche

    func testSearchAndFilterNarrowTheListTogether() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.searchQuery = "b"

        // „b" trifft Body Scan (15:42), Mindful Breathing (7:33) und beide von Anna Berg.
        // Nur Mindful Breathing erfuellt zusaetzlich die Dauer-Stufe.
        XCTAssertEqual(self.sut.visibleMeditations.map(\.name), ["Mindful Breathing"])
        XCTAssertEqual(self.sut.searchState, .results)
    }

    func testMeditationOutsideTheStepDisappearsFromSearchResults() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.searchQuery = "b"

        XCTAssertFalse(self.sut.visibleMeditations.contains { $0.name == "Body Scan" })
    }

    func testRemovingTheFilterBringsTheMeditationBackWithoutTouchingTheSearch() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.searchQuery = "b"

        self.sut.resetDurationFilter()

        XCTAssertTrue(self.sut.visibleMeditations.contains { $0.name == "Body Scan" })
        XCTAssertEqual(self.sut.searchQuery, "b")
    }

    func testSearchAndFilterWithoutCommonMatchShowEmptyState() {
        self.sut.selectDurationFilter(.over30)
        self.sut.searchQuery = "loving"

        XCTAssertTrue(self.sut.visibleMeditations.isEmpty)
        XCTAssertEqual(self.sut.searchState, .empty)
    }

    func testAvailableStepsFollowTheWholeLibraryNotTheCurrentSearch() {
        // „mindful" trifft nur die 7:33-Meditation — aber sobald Text im Suchfeld
        // steht, ist die Stufenzeile ohnehin dem Chip gewichen. Die Belegung bleibt
        // die der Bibliothek.
        self.sut.searchQuery = "mindful"

        XCTAssertEqual(self.sut.availableDurationSteps, Set(DurationFilter.allCases))
    }

    func testAvailableStepsIgnoreTheActiveFilterSoItStaysReversible() {
        self.sut.selectDurationFilter(.from5To15)

        // Ohne Suchtext bleibt jede belegte Stufe waehlbar — der Filter ist keine Einbahnstrasse.
        XCTAssertEqual(self.sut.availableDurationSteps, Set(DurationFilter.allCases))
    }

    func testSearchModeIsActiveWhileQueryPresentEvenWithoutFocus() {
        self.sut.searchQuery = "b"
        self.sut.isSearching = false

        XCTAssertTrue(self.sut.isSearchModeActive)
    }

    func testSearchModeIsInactiveWithoutFocusAndWithoutQuery() {
        self.sut.selectDurationFilter(.from5To15)

        XCTAssertFalse(self.sut.isSearchModeActive)
    }

    func testFilterChipStaysVisibleWhileTheHistoryIsShown() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.isSearching = true

        XCTAssertEqual(self.sut.searchState, .history)
        XCTAssertTrue(self.sut.isFilterActive)
    }

    // MARK: - Lebensdauer des Filters

    func testCancellingTheSearchKeepsTheFilterAndRestoresTheFilterRow() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.searchQuery = "b"
        self.sut.isSearching = true

        self.sut.resetSearch()

        XCTAssertEqual(self.sut.durationFilter, .from5To15)
        XCTAssertEqual(self.sut.searchQuery, "")
        XCTAssertEqual(self.sut.searchState, .filtered)
    }

    func testLeavingTheLibraryTabDropsTheFilter() {
        self.sut.selectDurationFilter(.from5To15)

        self.sut.resetDurationFilter()

        XCTAssertEqual(self.sut.durationFilter, .all)
        XCTAssertEqual(self.sut.searchState, .idle)
    }

    func testResettingSearchAndFilterTogetherClearsBoth() {
        self.sut.selectDurationFilter(.over30)
        self.sut.searchQuery = "loving"

        self.sut.resetSearchAndFilter()

        XCTAssertEqual(self.sut.durationFilter, .all)
        XCTAssertEqual(self.sut.searchQuery, "")
        XCTAssertEqual(self.sut.searchState, .idle)
    }

    // MARK: - Suchhistorie unter aktivem Filter

    func testTermWhoseMatchesTheFilterRemovesDoesNotEnterTheHistory() {
        // „mindful" trifft die 7:33-Meditation, der Filter raeumt sie weg —
        // der User sieht „Nichts gefunden" und darf den Begriff nicht wiederfinden.
        self.sut.selectDurationFilter(.over30)
        self.sut.searchQuery = "mindful"

        self.sut.submitSearch()

        XCTAssertEqual(self.sut.searchState, .empty)
        XCTAssertTrue(self.sut.searchHistory.isEmpty)
    }

    func testTermWithAVisibleMatchStillEntersTheHistory() {
        self.sut.selectDurationFilter(.from5To15)
        self.sut.searchQuery = "mindful"

        self.sut.submitSearch()

        XCTAssertEqual(self.sut.searchHistory, ["mindful"])
    }

    // MARK: - Nur Leerzeichen im Suchfeld

    func testWhitespaceOnlyInputIsNoSearchTermForTheEmptyStateText() {
        self.sut.searchQuery = "   "

        XCTAssertEqual(self.sut.trimmedSearchQuery, "")
    }

    // MARK: - Kein Treffer durch den Filter allein

    func testFilterWithoutAnyMatchingMeditationShowsEmptyState() {
        self.sut.selectDurationFilter(.over30)
        // Die einzige lange Meditation verschwindet aus der Bibliothek.
        self.sut.meditations = self.sut.meditations.filter { $0.name != "Long Sit" }

        XCTAssertTrue(self.sut.visibleMeditations.isEmpty)
        XCTAssertEqual(self.sut.searchState, .empty)
    }

    // MARK: - Helpers

    /// Bibliothek aus dem Ticket-Mockup: drei Lehrer:innen, sechs Dauern ueber alle Stufen.
    private func makeLibrary() -> [GuidedMeditation] {
        [
            self.makeMeditation(name: "Body Scan", teacher: "Sarah Kornfield", seconds: 942),
            self.makeMeditation(name: "Mindful Breathing", teacher: "Sarah Kornfield", seconds: 453),
            self.makeMeditation(name: "Loving Kindness", teacher: "Tara Goldstein", seconds: 737),
            self.makeMeditation(name: "Evening Wind", teacher: "Tara Goldstein", seconds: 1145),
            self.makeMeditation(name: "Quick Pause", teacher: "Anna Berg", seconds: 180),
            self.makeMeditation(name: "Long Sit", teacher: "Anna Berg", seconds: 2520)
        ]
    }

    private func makeMeditation(name: String, teacher: String, seconds: TimeInterval) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: seconds,
            teacher: teacher,
            name: name
        )
    }
}
