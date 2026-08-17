// MARK: - CaseAction.swift
// PersonalGuide
//
// A single step within a case that the user needs to perform.
// Actions are ordered and can have different types (read, upload, call, etc.)

import Foundation
import SwiftData

@Model
final class CaseAction {

    var id: UUID
    var title: String
    var descriptionText: String
    var orderIndex: Int
    var isRequired: Bool

    // MARK: - Classification

    var actionTypeRaw: String
    var statusRaw: String

    // MARK: - Dates

    var deadline: Date?
    var completedAt: Date?

    // MARK: - Context

    /// Source that suggested this action (e.g., "ai_planner", "user", "template").
    var source: String?

    /// External URL for OPEN_URL actions (e.g., merchant return page).
    var externalURL: String?

    /// Arbitrary metadata (JSON-encoded).
    var metadataJSON: String?

    // MARK: - Relationships

    var parentCase: PGCase?

    // MARK: - Init

    init(
        title: String,
        descriptionText: String = "",
        actionType: ActionType = .custom,
        status: ActionStatus = .notStarted,
        orderIndex: Int = 0,
        isRequired: Bool = true,
        deadline: Date? = nil,
        source: String? = nil,
        externalURL: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.actionTypeRaw = actionType.rawValue
        self.statusRaw = status.rawValue
        self.orderIndex = orderIndex
        self.isRequired = isRequired
        self.deadline = deadline
        self.source = source
        self.externalURL = externalURL
    }

    // MARK: - Computed

    var actionType: ActionType {
        get { ActionType(rawValue: actionTypeRaw) ?? .custom }
        set { actionTypeRaw = newValue.rawValue }
    }

    var status: ActionStatus {
        get { ActionStatus(rawValue: statusRaw) ?? .notStarted }
        set {
            statusRaw = newValue.rawValue
            if newValue == .completed {
                completedAt = .now
            }
        }
    }

    /// Marks this action as complete and returns the updated status.
    @discardableResult
    func markCompleted() -> ActionStatus {
        status = .completed
        return status
    }

    /// Marks this action as skipped.
    @discardableResult
    func markSkipped() -> ActionStatus {
        status = .skipped
        return status
    }
}
