//
//  NotificationServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Notifications
//

import Foundation
import UserNotifications

/// Protocol defining notification service behavior
protocol NotificationServiceProtocol {
    /// Requests notification permission from user
    func requestAuthorization() async throws -> Bool

    /// Schedules a notification for timer completion
    /// - Parameter timeInterval: Time in seconds until notification
    func scheduleTimerCompletionNotification(timeInterval: TimeInterval) throws

    /// Cancels all pending notifications
    func cancelAllNotifications()

    /// Checks current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
}
