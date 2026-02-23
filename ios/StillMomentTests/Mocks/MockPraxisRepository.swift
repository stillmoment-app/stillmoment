//
//  MockPraxisRepository.swift
//  Still Moment
//
//  Mock PraxisRepository for unit tests
//

import Foundation
@testable import StillMoment

final class MockPraxisRepository: PraxisRepository {
    var praxes: [Praxis] = [Praxis(name: "Standard")]
    var storedActivePraxisId: UUID?

    var activePraxisId: UUID? {
        self.storedActivePraxisId
    }

    func loadAll() -> [Praxis] {
        self.praxes
    }

    func load(byId id: UUID) -> Praxis? {
        self.praxes.first { $0.id == id }
    }

    func save(_ praxis: Praxis) {
        if let index = self.praxes.firstIndex(where: { $0.id == praxis.id }) {
            self.praxes[index] = praxis
        } else {
            self.praxes.append(praxis)
        }
    }

    func delete(id: UUID) throws {
        guard self.praxes.contains(where: { $0.id == id }) else {
            throw PraxisRepositoryError.praxisNotFound(id)
        }
        guard self.praxes.count > 1 else {
            throw PraxisRepositoryError.cannotDeleteLastPraxis
        }
        self.praxes.removeAll { $0.id == id }
    }

    func setActivePraxisId(_ id: UUID) {
        self.storedActivePraxisId = id
    }
}
