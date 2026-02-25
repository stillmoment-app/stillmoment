//
//  MockPraxisRepository.swift
//  Still Moment
//
//  Mock PraxisRepository for unit tests
//

import Foundation
@testable import StillMoment

final class MockPraxisRepository: PraxisRepository {
    var currentPraxis: Praxis = .default
    var saveCalled = false
    var savedPraxis: Praxis?

    func load() -> Praxis {
        self.currentPraxis
    }

    func save(_ praxis: Praxis) {
        self.currentPraxis = praxis
        self.saveCalled = true
        self.savedPraxis = praxis
    }
}
