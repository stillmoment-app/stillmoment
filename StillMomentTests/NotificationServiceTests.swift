//
//  NotificationServiceTests.swift
//  Still Moment
//

import UserNotifications
import XCTest
@testable import StillMoment

// MARK: - Mock Notification Service

final class MockNotificationService: NotificationServiceProtocol {
    var authorizationGranted = false
    var authorizationShouldThrow = false
    var requestAuthorizationCalled = false

    var scheduledNotifications: [TimeInterval] = []
    var scheduleShouldThrow = false

    var cancelAllCalled = false

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var checkAuthorizationCalled = false

    func requestAuthorization() async throws -> Bool {
        self.requestAuthorizationCalled = true
        if self.authorizationShouldThrow {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        return self.authorizationGranted
    }

    func scheduleTimerCompletionNotification(timeInterval: TimeInterval) throws {
        if self.scheduleShouldThrow {
            throw NSError(domain: "MockError", code: 2, userInfo: nil)
        }
        self.scheduledNotifications.append(timeInterval)
    }

    func cancelAllNotifications() {
        self.cancelAllCalled = true
        self.scheduledNotifications.removeAll()
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        self.checkAuthorizationCalled = true
        return self.authorizationStatus
    }
}

// MARK: - NotificationServiceTests

final class NotificationServiceTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: MockNotificationService!

    override func setUp() {
        super.setUp()
        self.sut = MockNotificationService()
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorizationGranted() async throws {
        // Given
        self.sut.authorizationGranted = true

        // When
        let granted = try await sut.requestAuthorization()

        // Then
        XCTAssertTrue(self.sut.requestAuthorizationCalled)
        XCTAssertTrue(granted)
    }

    func testRequestAuthorizationDenied() async throws {
        // Given
        self.sut.authorizationGranted = false

        // When
        let granted = try await sut.requestAuthorization()

        // Then
        XCTAssertTrue(self.sut.requestAuthorizationCalled)
        XCTAssertFalse(granted)
    }

    func testRequestAuthorizationThrows() async {
        // Given
        self.sut.authorizationShouldThrow = true

        // When/Then
        do {
            _ = try await self.sut.requestAuthorization()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(self.sut.requestAuthorizationCalled)
        }
    }

    func testCheckAuthorizationStatusAuthorized() async {
        // Given
        self.sut.authorizationStatus = .authorized

        // When
        let status = await sut.checkAuthorizationStatus()

        // Then
        XCTAssertTrue(self.sut.checkAuthorizationCalled)
        XCTAssertEqual(status, .authorized)
    }

    func testCheckAuthorizationStatusNotDetermined() async {
        // Given
        self.sut.authorizationStatus = .notDetermined

        // When
        let status = await sut.checkAuthorizationStatus()

        // Then
        XCTAssertTrue(self.sut.checkAuthorizationCalled)
        XCTAssertEqual(status, .notDetermined)
    }

    func testCheckAuthorizationStatusDenied() async {
        // Given
        self.sut.authorizationStatus = .denied

        // When
        let status = await sut.checkAuthorizationStatus()

        // Then
        XCTAssertTrue(self.sut.checkAuthorizationCalled)
        XCTAssertEqual(status, .denied)
    }

    // MARK: - Notification Scheduling Tests

    func testScheduleTimerCompletionNotification() throws {
        // Given
        let timeInterval: TimeInterval = 60.0

        // When
        try sut.scheduleTimerCompletionNotification(timeInterval: timeInterval)

        // Then
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)
        XCTAssertEqual(self.sut.scheduledNotifications.first, 60.0)
    }

    func testScheduleMultipleNotifications() throws {
        // When
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 120.0)

        // Then
        XCTAssertEqual(self.sut.scheduledNotifications.count, 2)
        XCTAssertEqual(self.sut.scheduledNotifications[0], 60.0)
        XCTAssertEqual(self.sut.scheduledNotifications[1], 120.0)
    }

    func testScheduleNotificationWithZeroInterval() throws {
        // When
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 0.1)

        // Then
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)
        XCTAssertEqual(self.sut.scheduledNotifications.first, 0.1)
    }

    func testScheduleNotificationWithLargeInterval() throws {
        // When
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 3600.0)

        // Then
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)
        XCTAssertEqual(self.sut.scheduledNotifications.first, 3600.0)
    }

    func testScheduleNotificationThrows() {
        // Given
        self.sut.scheduleShouldThrow = true

        // When/Then
        XCTAssertThrowsError(
            try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)
        )
    }

    // MARK: - Cancellation Tests

    func testCancelAllNotifications() throws {
        // Given
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)

        // When
        self.sut.cancelAllNotifications()

        // Then
        XCTAssertTrue(self.sut.cancelAllCalled)
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)
    }

    func testCancelNotificationsWhenNonePending() {
        // When
        self.sut.cancelAllNotifications()

        // Then
        XCTAssertTrue(self.sut.cancelAllCalled)
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)
    }

    func testMultipleCancellations() throws {
        // Given
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)

        // When
        self.sut.cancelAllNotifications()
        self.sut.cancelAllNotifications()
        self.sut.cancelAllNotifications()

        // Then
        XCTAssertTrue(self.sut.cancelAllCalled)
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)
    }

    // MARK: - Integration Tests

    func testScheduleAfterCancellation() throws {
        // Given
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)
        self.sut.cancelAllNotifications()
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)

        // When
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 120.0)

        // Then
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)
        XCTAssertEqual(self.sut.scheduledNotifications.first, 120.0)
    }

    func testFullNotificationFlow() throws {
        // Given
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)

        // When - Schedule notification
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 300.0)

        // Then - Verify scheduled
        XCTAssertEqual(self.sut.scheduledNotifications.count, 1)
        XCTAssertEqual(self.sut.scheduledNotifications.first, 300.0)

        // When - Cancel
        self.sut.cancelAllNotifications()

        // Then - Verify cancelled
        XCTAssertTrue(self.sut.cancelAllCalled)
        XCTAssertEqual(self.sut.scheduledNotifications.count, 0)
    }
}
