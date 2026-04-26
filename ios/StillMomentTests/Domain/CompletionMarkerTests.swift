//
//  CompletionMarkerTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

final class CompletionMarkerTests: XCTestCase {
    private let ttl: TimeInterval = 8 * 3600
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

    // MARK: - isExpired

    func testNoMarkerIsExpired() {
        // completedAt == 0 means no marker set
        XCTAssertTrue(CompletionMarker.isExpired(completedAt: 0, now: self.referenceDate))
    }

    func testFreshMarkerIsNotExpired() {
        // Completed 1 minute ago
        let completedAt = self.referenceDate.timeIntervalSince1970 - 60
        XCTAssertFalse(CompletionMarker.isExpired(completedAt: completedAt, now: self.referenceDate))
    }

    func testMarkerJustWithinTTLIsNotExpired() {
        // Completed exactly at TTL boundary minus 1 second
        let completedAt = self.referenceDate.timeIntervalSince1970 - self.ttl + 1
        XCTAssertFalse(CompletionMarker.isExpired(completedAt: completedAt, now: self.referenceDate))
    }

    func testMarkerExactlyAtTTLIsExpired() {
        // Completed exactly ttl seconds ago
        let completedAt = self.referenceDate.timeIntervalSince1970 - self.ttl
        XCTAssertTrue(CompletionMarker.isExpired(completedAt: completedAt, now: self.referenceDate))
    }

    func testMarkerBeyondTTLIsExpired() {
        // Completed 9 hours ago (ttl = 8h)
        let completedAt = self.referenceDate.timeIntervalSince1970 - 9 * 3600
        XCTAssertTrue(CompletionMarker.isExpired(completedAt: completedAt, now: self.referenceDate))
    }

    func testCustomTTLRespected() {
        let customTTL: TimeInterval = 3600
        let completedAt = self.referenceDate.timeIntervalSince1970 - 1800
        XCTAssertFalse(CompletionMarker.isExpired(completedAt: completedAt, now: self.referenceDate, ttl: customTTL))
        XCTAssertTrue(CompletionMarker.isExpired(
            completedAt: completedAt - 1800,
            now: self.referenceDate,
            ttl: customTTL
        ))
    }

    func testDefaultTTLIs8Hours() {
        XCTAssertEqual(CompletionMarker.defaultTTL, 8 * 3600)
    }
}
