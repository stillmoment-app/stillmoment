//
//  PraxisSelectionViewModelTests.swift
//  Still Moment
//
//  Tests for PraxisSelectionViewModel
//

import XCTest
@testable import StillMoment

@MainActor
final class PraxisSelectionViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: PraxisSelectionViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockRepository: MockPraxisRepository!
    var selectedPraxis: Praxis?

    override func setUp() {
        super.setUp()
        self.mockRepository = MockPraxisRepository()
        self.selectedPraxis = nil
        self.sut = PraxisSelectionViewModel(
            repository: self.mockRepository
        ) { [weak self] praxis in
            self?.selectedPraxis = praxis
        }
    }

    override func tearDown() {
        self.sut = nil
        self.mockRepository = nil
        self.selectedPraxis = nil
        super.tearDown()
    }

    // MARK: - Load

    func testLoad_populatesPraxes() {
        // Given: repository has one praxis
        XCTAssertEqual(self.mockRepository.praxes.count, 1)

        // When
        self.sut.load()

        // Then
        XCTAssertEqual(self.sut.praxes.count, 1)
    }

    func testLoad_setsActivePraxisIdFromRepository() {
        // Given: repository has a stored active ID
        let id = self.mockRepository.praxes[0].id
        self.mockRepository.storedActivePraxisId = id

        // When
        self.sut.load()

        // Then
        XCTAssertEqual(self.sut.activePraxisId, id)
    }

    func testLoad_withNoStoredActiveId_usesFirstPraxis() {
        // Given: no stored active ID
        self.mockRepository.storedActivePraxisId = nil

        // When
        self.sut.load()

        // Then: falls back to first praxis
        XCTAssertEqual(self.sut.activePraxisId, self.mockRepository.praxes.first?.id)
    }

    // MARK: - Select

    func testSelectPraxis_updatesActivePraxisId() {
        // Given
        self.sut.load()
        let praxis = self.mockRepository.praxes[0]

        // When
        self.sut.selectPraxis(praxis)

        // Then
        XCTAssertEqual(self.sut.activePraxisId, praxis.id)
    }

    func testSelectPraxis_callsOnPraxisSelected() {
        // Given
        self.sut.load()
        let praxis = self.mockRepository.praxes[0]

        // When
        self.sut.selectPraxis(praxis)

        // Then
        XCTAssertEqual(self.selectedPraxis, praxis)
    }

    func testSelectPraxis_persistsActivePraxisIdInRepository() {
        // Given
        self.sut.load()
        let praxis = self.mockRepository.praxes[0]

        // When
        self.sut.selectPraxis(praxis)

        // Then
        XCTAssertEqual(self.mockRepository.storedActivePraxisId, praxis.id)
    }

    // MARK: - Create

    func testCreateNewPraxis_addsToList() {
        // Given
        self.sut.load()
        let countBefore = self.sut.praxes.count

        // When
        self.sut.createNewPraxis()

        // Then
        XCTAssertEqual(self.sut.praxes.count, countBefore + 1)
    }

    func testCreateNewPraxis_selectsNewPraxis() {
        // Given
        self.sut.load()

        // When
        let newPraxis = self.sut.createNewPraxis()

        // Then
        XCTAssertEqual(self.sut.activePraxisId, newPraxis.id)
        XCTAssertEqual(self.selectedPraxis, newPraxis)
    }

    // MARK: - Delete

    func testRequestDelete_setsPraxisToDelete() {
        // Given
        self.sut.load()
        let praxis = self.mockRepository.praxes[0]

        // When
        self.sut.requestDelete(praxis)

        // Then
        XCTAssertEqual(self.sut.praxisToDelete, praxis)
    }

    func testConfirmDelete_withMultiplePraxes_removesPraxis() throws {
        // Given: two praxes
        let id1 = UUID()
        let id2 = UUID()
        self.mockRepository.praxes = [
            Praxis(id: id1, name: "First"),
            Praxis(id: id2, name: "Second")
        ]
        self.sut.load()
        let praxisToDelete = try XCTUnwrap(self.sut.praxes.first { $0.id == id2 })
        self.sut.requestDelete(praxisToDelete)

        // When
        self.sut.confirmDelete()

        // Then
        XCTAssertEqual(self.sut.praxes.count, 1)
        XCTAssertFalse(self.sut.praxes.contains { $0.id == id2 })
    }

    func testConfirmDelete_lastPraxis_setsErrorMessage() {
        // Given: only one praxis
        self.sut.load()
        let onlyPraxis = self.sut.praxes[0]
        self.sut.requestDelete(onlyPraxis)

        // When
        self.sut.confirmDelete()

        // Then: error set, praxis not deleted
        XCTAssertNotNil(self.sut.errorMessage)
        XCTAssertEqual(self.sut.praxes.count, 1)
    }

    func testConfirmDelete_clearsPraxisToDelete() {
        // Given: two praxes
        self.mockRepository.praxes = [
            Praxis(id: UUID(), name: "First"),
            Praxis(id: UUID(), name: "Second")
        ]
        self.sut.load()
        self.sut.requestDelete(self.sut.praxes[0])

        // When
        self.sut.confirmDelete()

        // Then
        XCTAssertNil(self.sut.praxisToDelete)
    }

    func testConfirmDelete_activeWasDeleted_switchesToRemainingPraxis() throws {
        // Given: two praxes, first is active
        let id1 = UUID()
        let id2 = UUID()
        self.mockRepository.praxes = [
            Praxis(id: id1, name: "First"),
            Praxis(id: id2, name: "Second")
        ]
        self.mockRepository.storedActivePraxisId = id1
        self.sut.load()
        let firstPraxis = try XCTUnwrap(self.sut.praxes.first { $0.id == id1 })
        self.sut.requestDelete(firstPraxis)

        // When
        self.sut.confirmDelete()

        // Then: switches to remaining praxis
        XCTAssertNotNil(self.selectedPraxis)
        XCTAssertEqual(self.sut.activePraxisId, id2)
    }

    // MARK: - canDeletePraxis

    func testCanDeletePraxis_withOnePraxis_returnsFalse() {
        self.sut.load()
        XCTAssertFalse(self.sut.canDeletePraxis)
    }

    func testCanDeletePraxis_withMultiplePraxes_returnsTrue() {
        self.mockRepository.praxes = [
            Praxis(id: UUID(), name: "First"),
            Praxis(id: UUID(), name: "Second")
        ]
        self.sut.load()
        XCTAssertTrue(self.sut.canDeletePraxis)
    }

    // MARK: - activePraxis

    func testActivePraxis_withMatchingId_returnsCorrectPraxis() {
        let id = UUID()
        let praxis = Praxis(id: id, name: "Morning")
        self.mockRepository.praxes = [praxis]
        self.mockRepository.storedActivePraxisId = id
        self.sut.load()
        XCTAssertEqual(self.sut.activePraxis, praxis)
    }

    func testActivePraxis_withNoId_returnsFirstPraxis() {
        self.mockRepository.storedActivePraxisId = nil
        self.sut.load()
        XCTAssertEqual(self.sut.activePraxis, self.mockRepository.praxes.first)
    }
}
