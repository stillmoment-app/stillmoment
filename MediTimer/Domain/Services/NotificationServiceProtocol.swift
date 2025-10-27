//
//  NotificationServiceProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Notifications
//

import Foundation

/// Protocol defining notification service behavior
protocol NotificationServiceProtocol {
    /// Requests notification permission from user
    func requestAuthorization() async throws -> Bool

    /// Schedules a notification for timer completion
    /// - Parameter timeInterval: Time in seconds until notification
    func scheduleTimerCompletionNotification(timeInterval: TimeInterval) throws

    /// Cancels all pending notifications
    func cancelAllNotifications()
}
