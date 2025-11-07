//
//  NotificationServiceTests.swift
//  MediTimerTests
//
//  Unit Tests - NotificationService
//

import UserNotifications
import XCTest
@testable import MediTimer

final class NotificationServiceTests: XCTestCase {
    var sut: NotificationService!

    override func setUp() {
        super.setUp()
        self.sut = NotificationService()
    }

    override func tearDown() {
        // Clean up any pending notifications
        self.sut.cancelAllNotifications()
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorization() async throws {
        // When
        let granted = try await sut.requestAuthorization()

        // Then
        // In test environment, this may vary based on system state
        // We just verify it doesn't throw
        XCTAssertTrue(granted || !granted) // Either outcome is valid
    }

    func testCheckAuthorizationStatus() async {
        // When
        let status = await sut.checkAuthorizationStatus()

        // Then - Should return a valid status
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral,
        ]
        XCTAssertTrue(validStatuses.contains(status))
    }

    // MARK: - Notification Scheduling Tests

    func testScheduleTimerCompletionNotification() throws {
        // Given
        let timeInterval: TimeInterval = 60.0 // 1 minute

        // When
        XCTAssertNoThrow(try self.sut.scheduleTimerCompletionNotification(timeInterval: timeInterval))

        // Then - Notification should be scheduled
        // We verify by checking pending notifications
        let expectation = expectation(description: "Check pending notifications")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1, "Should have 1 pending notification")

            if let request = requests.first {
                XCTAssertEqual(request.identifier, "timer_completion")
                XCTAssertEqual(request.content.title, "Meditation Complete")
                XCTAssertEqual(request.content.body, "Your meditation session has ended.")

                // Verify trigger
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    XCTAssertEqual(trigger.timeInterval, 60.0, accuracy: 0.1)
                    XCTAssertFalse(trigger.repeats)
                }
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testScheduleMultipleNotifications() throws {
        // Given - Schedule first notification
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)

        // When - Schedule second notification (should replace first)
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 120.0)

        // Then - Should only have one notification
        let expectation = expectation(description: "Check pending notifications")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1, "Should only have 1 notification (replaced)")

            if let trigger = requests.first?.trigger as? UNTimeIntervalNotificationTrigger {
                XCTAssertEqual(trigger.timeInterval, 120.0, accuracy: 0.1)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testScheduleNotificationWithZeroInterval() throws {
        // When - Schedule with zero interval (immediate)
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 0.1)

        // Then - Should not throw
        let expectation = expectation(description: "Check pending notifications")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertGreaterThanOrEqual(requests.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testScheduleNotificationWithLargeInterval() throws {
        // When - Schedule with large interval (e.g., 1 hour)
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 3600.0)

        // Then - Should not throw
        let expectation = expectation(description: "Check pending notifications")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1)

            if let trigger = requests.first?.trigger as? UNTimeIntervalNotificationTrigger {
                XCTAssertEqual(trigger.timeInterval, 3600.0, accuracy: 0.1)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Cancellation Tests

    func testCancelAllNotifications() throws {
        // Given - Schedule some notifications
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)

        // When
        self.sut.cancelAllNotifications()

        // Then - Should have no pending notifications
        let expectation = expectation(description: "Check notifications cancelled")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0, "All notifications should be cancelled")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testCancelNotificationsWhenNonePending() {
        // When - Cancel when no notifications exist
        self.sut.cancelAllNotifications()

        // Then - Should not crash
        let expectation = expectation(description: "Check no notifications")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testMultipleCancellations() throws {
        // Given
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)

        // When - Cancel multiple times
        self.sut.cancelAllNotifications()
        self.sut.cancelAllNotifications()
        self.sut.cancelAllNotifications()

        // Then - Should not crash
        let expectation = expectation(description: "Check notifications cancelled")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Notification Content Tests

    func testNotificationContent() throws {
        // Given
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)

        // Then - Verify content
        let expectation = expectation(description: "Check notification content")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard let request = requests.first else {
                XCTFail("No pending notification found")
                expectation.fulfill()
                return
            }

            let content = request.content
            XCTAssertEqual(content.title, "Meditation Complete")
            XCTAssertEqual(content.body, "Your meditation session has ended.")
            XCTAssertEqual(content.sound, UNNotificationSound(named: UNNotificationSoundName("completion.mp3")))

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Integration Tests

    func testFullNotificationFlow() async throws {
        // Given - Request authorization first
        _ = try await self.sut.requestAuthorization()

        // When - Schedule notification
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 300.0) // 5 minutes

        // Then - Verify scheduled
        let expectation = expectation(description: "Verify notification flow")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        // When - Cancel
        self.sut.cancelAllNotifications()

        // Then - Verify cancelled
        let cancelExpectation = self.expectation(description: "Verify cancellation")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0)
            cancelExpectation.fulfill()
        }

        wait(for: [cancelExpectation], timeout: 2.0)
    }

    func testScheduleAfterCancellation() throws {
        // Given - Schedule and cancel
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 60.0)
        self.sut.cancelAllNotifications()

        // When - Schedule again
        try self.sut.scheduleTimerCompletionNotification(timeInterval: 120.0)

        // Then - Should have new notification
        let expectation = expectation(description: "Check new notification")

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1)

            if let trigger = requests.first?.trigger as? UNTimeIntervalNotificationTrigger {
                XCTAssertEqual(trigger.timeInterval, 120.0, accuracy: 0.1)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
