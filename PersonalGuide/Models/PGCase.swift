// MARK: - PGCase.swift
// PersonalGuide
//
// Core data model. A Case represents a real-world administrative outcome
// the user is trying to achieve — NOT a reminder, NOT a to-do item.
//
// Examples: "Renew passport", "Return Amazon headphones", "Cancel Netflix"

import Foundation
import SwiftData

@Model
final class PGCase {

    // MARK: - Identity

    var id: UUID
    var title: String
    var descriptionText: String

    // MARK: - Classification

    var caseTypeRaw: String
    var category: String?
    var sourceRaw: String

    // MARK: - Lifecycle

    var statusRaw: String
    var priorityRaw: String
    var confidence: Double

    // MARK: - Dates

    var deadline: Date?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    // MARK: - References

    var externalReference: String?

    /// Arbitrary key-value metadata for extensibility.
    /// Stored as JSON-encoded dictionary.
    var metadataJSON: String?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \CaseAction.parentCase)
    var actions: [CaseAction] = []

    @Relationship(deleteRule: .cascade, inverse: \CaseRequirement.parentCase)
    var requirements: [CaseRequirement] = []

    @Relationship(deleteRule: .nullify, inverse: \PGDocument.parentCase)
    var documents: [PGDocument] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.parentCase)
    var reminders: [Reminder] = []

    @Relationship(deleteRule: .cascade, inverse: \ActivityEvent.parentCase)
    var events: [ActivityEvent] = []

    var relatedAsset: Asset?
    var relatedPerson: Person?

    // MARK: - Init

    init(
        title: String,
        descriptionText: String = "",
        caseType: CaseType = .genericLifeAdmin,
        source: CaseSource = .manualEntry,
        status: CaseStatus = .draft,
        priority: CasePriority = .normal,
        confidence: Double = 1.0,
        deadline: Date? = nil,
        category: String? = nil,
        externalReference: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.caseTypeRaw = caseType.rawValue
        self.sourceRaw = source.rawValue
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.confidence = confidence
        self.deadline = deadline
        self.category = category ?? caseType.defaultCategory
        self.externalReference = externalReference
        self.createdAt = .now
        self.updatedAt = .now
    }

    // MARK: - Computed Properties

    var caseType: CaseType {
        get { CaseType(rawValue: caseTypeRaw) ?? .genericLifeAdmin }
        set { caseTypeRaw = newValue.rawValue }
    }

    var status: CaseStatus {
        get { CaseStatus(rawValue: statusRaw) ?? .draft }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
            if newValue == .completed {
                completedAt = .now
            }
        }
    }

    var priority: CasePriority {
        get { CasePriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    var source: CaseSource {
        get { CaseSource(rawValue: sourceRaw) ?? .manualEntry }
        set { sourceRaw = newValue.rawValue }
    }

    /// The next incomplete, actionable step in the case.
    var nextAction: CaseAction? {
        sortedActions.first { $0.status.isActionable || $0.status == .notStarted }
    }

    /// Actions sorted by their order index.
    var sortedActions: [CaseAction] {
        actions.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Number of completed steps out of total required steps.
    var completionProgress: (completed: Int, total: Int) {
        let required = actions.filter { $0.isRequired }
        let done = required.filter { $0.status.isDone }
        return (done.count, required.count)
    }

    /// Fractional completion (0.0 – 1.0).
    var completionFraction: Double {
        let progress = completionProgress
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    /// Whether the case's deadline has passed.
    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < .now
    }

    /// Days remaining until deadline (negative if overdue).
    var daysUntilDeadline: Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day
    }

    /// Requirements that the user still needs to provide.
    var unsatisfiedRequirements: [CaseRequirement] {
        requirements.filter { $0.requirementStatus.needsUserAction }
    }

    /// Whether all requirements are satisfied.
    var allRequirementsMet: Bool {
        requirements.allSatisfy { $0.requirementStatus.isSatisfied }
    }

    // MARK: - Metadata helpers

    var metadata: [String: String] {
        get {
            guard let json = metadataJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8)
            else { return }
            metadataJSON = json
        }
    }
}
