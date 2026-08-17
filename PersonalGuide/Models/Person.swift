// MARK: - Person.swift
// PersonalGuide
//
// People / family model. MVP is single-user but the schema supports
// linking cases/documents/assets to specific people (e.g., family members).

import Foundation
import SwiftData

@Model
final class Person {

    var id: UUID
    var name: String
    var relationship: String?
    var metadataJSON: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \PGCase.relatedPerson)
    var cases: [PGCase] = []

    init(name: String, relationship: String? = nil) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.createdAt = .now
    }
}

// MARK: - Reminder.swift

/// A supporting notification — NOT the core product.
/// Reminders point toward actions, never standalone.
@Model
final class Reminder {

    var id: UUID
    var triggerAt: Date
    var reminderTypeRaw: String
    var statusRaw: String
    var message: String

    var parentCase: PGCase?

    /// The specific action this reminder relates to (optional).
    var actionId: UUID?

    init(
        triggerAt: Date,
        reminderType: ReminderType = .upcoming,
        message: String
    ) {
        self.id = UUID()
        self.triggerAt = triggerAt
        self.reminderTypeRaw = reminderType.rawValue
        self.statusRaw = ReminderStatus.scheduled.rawValue
        self.message = message
    }

    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRaw) ?? .upcoming }
        set { reminderTypeRaw = newValue.rawValue }
    }

    var reminderStatus: ReminderStatus {
        get { ReminderStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }
}

// MARK: - ActivityEvent.swift

/// A single entry in a case's activity timeline.
/// Creates a trustworthy record of what happened and when.
@Model
final class ActivityEvent {

    var id: UUID
    var eventTypeRaw: String
    var title: String
    var detail: String?
    var timestamp: Date

    var parentCase: PGCase?

    init(
        eventType: ActivityEventType,
        title: String,
        detail: String? = nil
    ) {
        self.id = UUID()
        self.eventTypeRaw = eventType.rawValue
        self.title = title
        self.detail = detail
        self.timestamp = .now
    }

    var eventType: ActivityEventType {
        get { ActivityEventType(rawValue: eventTypeRaw) ?? .caseUpdated }
        set { eventTypeRaw = newValue.rawValue }
    }
}
