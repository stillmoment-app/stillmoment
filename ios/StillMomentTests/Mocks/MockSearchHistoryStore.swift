//
//  MockSearchHistoryStore.swift
//  Still Moment
//
//  In-Memory-Mock fuer SearchHistoryStore (ios-041).
//

import Foundation
@testable import StillMoment

final class MockSearchHistoryStore: SearchHistoryStore {
    var storedHistory: [String] = []
    private(set) var saveCallCount = 0

    func load() -> [String] {
        self.storedHistory
    }

    func save(_ history: [String]) {
        self.storedHistory = history
        self.saveCallCount += 1
    }
}
