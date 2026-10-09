//
//  MockMeditationSourceRepository.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockMeditationSourceRepository: MeditationSourceRepositoryProtocol {
    var sourcesByLanguage: [String: [MeditationSource]] = [:]
    private(set) var catalogCallCount = 0

    func catalog() -> MeditationSourceCatalog {
        self.catalogCallCount += 1
        return MeditationSourceCatalog(sourcesByLanguage: self.sourcesByLanguage)
    }
}
