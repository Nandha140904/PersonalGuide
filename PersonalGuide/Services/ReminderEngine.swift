// MARK: - ReminderEngine.swift
// PersonalGuide
//
// Deterministic reminder scheduling per spec section 16.
// Reminders are a SUPPORTING feature — they point toward actions, not standalone.
//
// Schedule:
//   30 days before → UPCOMING
//   14 days before → APPROACHING
//    7 days before → ACTION_REQUIRED
//    3 days before → URGENT
//    1 day before  → FINAL

import Foundation
import UserNotifications
import SwiftData

/// Manages deterministic reminder scheduling and local notification delivery.
///
/// The schedule is rule-based, not AI-driven. Users can customize thresholds.
@Observable
final class ReminderEngine {

    // MARK: - Default Thresholds (days before deadline)

    struct Thresholds {
        var upcoming: Int = 30
        var approaching: Int = 14
        var actionRequired: Int = 7
        var urgent: Int = 3
        var final_: Int = 1

        var allDays: [Int] {
            [upcoming, approaching, actionRequired, urgent, final_]
        }
    }

    var thresholds = Thresholds()

    // MARK: - Schedule Generation

    /// Generate the set of reminders that should exist for a case based on its deadline.
    func generateReminders(for pgCase: PGCase) -> [Reminder] {
        guard let deadline = pgCase.deadline else { return [] }
        let calendar = Calendar.current

        var reminders: [Reminder] = []

        let schedule: [(days: Int, type: ReminderType, label: String)] = [
            (thresholds.upcoming,       .upcoming,       "upcoming"),
            (thresholds.approaching,    .upcoming,       "approaching"),
            (thresholds.actionRequired, .actionRequired, "action required"),
            (thresholds.urgent,         .deadline,       "urgent"),
            (thresholds.final_,         .deadline,       "final reminder"),
        ]

        for entry in schedule {
            guard let triggerDate = calendar.date(byAdding: .day, value: -entry.days, to: deadline) else {
                continue
            }

            // Only create future reminders
            guard triggerDate > .now else { continue }

            let message = buildMessage(
                caseTitle: pgCase.title,
                caseType: pgCase.caseType,
                daysRemaining: entry.days,
                label: entry.label,
                progress: pgCase.completionProgress
            )

            let reminder = Reminder(
                triggerAt: triggerDate,
                reminderType: entry.type,
                message: message
            )
            reminder.parentCase = pgCase
            reminders.append(reminder)
        }

        return reminders
    }

    // MARK: - Message Building

    /// Build an action-oriented notification message (not just "Reminder: X").
    ///
    /// Good: "🚗 Car insurance renewal is ready. 3 steps remaining. [Continue]"
    /// Bad:  "Reminder: Car insurance."
    private func buildMessage(
        caseTitle: String,
        caseType: CaseType,
        daysRemaining: Int,
        label: String,
        progress: (completed: Int, total: Int)
    ) -> String {
        let emoji = caseTypeEmoji(caseType)
        let stepsRemaining = progress.total - progress.completed

        if daysRemaining <= 1 {
            return "\(emoji) \(caseTitle) is due tomorrow. \(stepsRemaining) step\(stepsRemaining == 1 ? "" : "s") remaining."
        } else if daysRemaining <= 3 {
            return "\(emoji) \(caseTitle) is due in \(daysRemaining) days. \(stepsRemaining) step\(stepsRemaining == 1 ? "" : "s") to complete."
        } else if daysRemaining <= 7 {
            return "\(emoji) \(caseTitle) needs your attention this week. \(stepsRemaining) step\(stepsRemaining == 1 ? "" : "s") remaining."
        } else {
            return "\(emoji) \(caseTitle) is coming up in \(daysRemaining) days."
        }
    }

    private func caseTypeEmoji(_ type: CaseType) -> String {
        switch type {
        case .purchaseReturn:    return "🛍️"
        case .subscriptionBill:  return "💳"
        case .documentRenewal:   return "📄"
        case .insuranceWarranty: return "🛡️"
        case .genericLifeAdmin:  return "📋"
        }
    }

    // MARK: - Local Notification Scheduling

    /// Schedule a local notification for a reminder.
    func scheduleNotification(for reminder: Reminder, caseTitle: String) async throws {
        let center = UNUserNotificationCenter.current()

        // Request permission if needed
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .notDetermined else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Personal Guide"
        content.subtitle = caseTitle
        content.body = reminder.message
        content.sound = .default
        content.categoryIdentifier = "CASE_ACTION"

        // Use the reminder's trigger date
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.triggerAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        reminder.reminderStatus = .scheduled
    }

    /// Cancel a scheduled notification.
    func cancelNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        reminder.reminderStatus = .cancelled
    }

    /// Cancel all notifications for a case.
    func cancelAllNotifications(for pgCase: PGCase) {
        let ids = pgCase.reminders.map { $0.id.uuidString }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
        pgCase.reminders.forEach { $0.reminderStatus = .cancelled }
    }
}
