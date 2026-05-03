//
//  MockMeditationSourceRepository.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockMeditationSourceRepository: MeditationSourceRepositoryProtocol {
    var catalog: [String: [MeditationSource]] = [:]
    private(set) var sourcesCallCount = 0
    private(set) var lastRequestedLanguage: String?

    func sources(for languageCode: String) -> [MeditationSource] {
        self.sourcesCallCount += 1
        self.lastRequestedLanguage = languageCode
        return self.catalog[languageCode] ?? self.catalog["en"] ?? []
    }
}
