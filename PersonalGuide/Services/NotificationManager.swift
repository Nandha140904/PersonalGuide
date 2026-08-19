// MARK: - NotificationManager.swift
// PersonalGuide
//
// Action-oriented notification scheduling using Apple's UserNotifications framework.
// Adheres strictly to the spec rule: Notifications are actionable and tell the user what to do next.

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationManager {

    static let shared = NotificationManager()

    var isAuthorized: Bool = false

    init() {
        checkAuthorization()
    }

    // MARK: - Permissions

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            self.isAuthorized = granted
            return granted
        } catch {
            self.isAuthorized = false
            return false
        }
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Reminders for Case

    func scheduleReminders(for pgCase: PGCase, reminders: [Reminder]) {
        guard isAuthorized else { return }

        // Cancel previous reminders for this case first
        cancelReminders(for: pgCase)

        let center = UNUserNotificationCenter.current()

        for reminder in reminders {
            guard reminder.reminderStatus == .scheduled, reminder.triggerAt > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = pgCase.title
            content.body = reminder.message
            content.sound = .default
            content.categoryIdentifier = "PERSONAL_GUIDE_ACTION"
            content.userInfo = ["case_id": pgCase.id.uuidString]

            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.triggerAt
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    // MARK: - Cancel Reminders

    func cancelReminders(for pgCase: PGCase) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let caseIdentifiers = requests
                .filter { ($0.content.userInfo["case_id"] as? String) == pgCase.id.uuidString }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: caseIdentifiers)
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
