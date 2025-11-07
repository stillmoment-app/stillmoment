//
//  NotificationService.swift
//  MediTimer
//
//  Infrastructure - Local Notification Service
//

import Foundation
import OSLog
import UserNotifications

/// Service for managing local notifications
final class NotificationService: NotificationServiceProtocol {
    // MARK: Internal

    // MARK: - Public Methods

    /// Requests notification permission from user
    func requestAuthorization() async throws -> Bool {
        try await self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Schedules a notification for timer completion
    /// - Parameter timeInterval: Time in seconds until notification
    func scheduleTimerCompletionNotification(timeInterval: TimeInterval) throws {
        // Remove any existing notifications
        self.notificationCenter.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Meditation Complete"
        content.body = "Your meditation session has ended."
        // Use custom Tibetan Singing Bowl sound
        content.sound = UNNotificationSound(named: UNNotificationSoundName("completion.mp3"))

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "timer_completion",
            content: content,
            trigger: trigger
        )

        self.notificationCenter.add(request) { error in
            if let error {
                Logger.notifications.error("Failed to schedule notification", error: error)
            }
        }
    }

    /// Cancels all pending notifications
    func cancelAllNotifications() {
        self.notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Checks current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: Private

    private let notificationCenter = UNUserNotificationCenter.current()
}
