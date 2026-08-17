// MARK: - CaseService.swift
// PersonalGuide
//
// Business logic for case lifecycle management.
// Coordinates between WorkflowEngine, PriorityEngine, ReminderEngine.

import Foundation
import SwiftData

/// Central service for creating, updating, and managing life-admin cases.
///
/// All case mutations flow through this service to ensure:
/// - Workflow transitions are validated
/// - Activity events are recorded
/// - Reminders are generated/updated
/// - Related entities are properly linked
@Observable
final class CaseService {

    let workflowEngine: WorkflowEngine
    let priorityEngine: PriorityEngine
    let reminderEngine: ReminderEngine

    init(
        workflowEngine: WorkflowEngine = WorkflowEngine(),
        priorityEngine: PriorityEngine = PriorityEngine(),
        reminderEngine: ReminderEngine = ReminderEngine()
    ) {
        self.workflowEngine = workflowEngine
        self.priorityEngine = priorityEngine
        self.reminderEngine = reminderEngine
    }

    // MARK: - Create

    /// Create a new case from a structured draft.
    ///
    /// This is the final step after the user has confirmed the AI-generated
    /// or manually-created case preview.
    @discardableResult
    func createCase(
        title: String,
        descriptionText: String = "",
        caseType: CaseType,
        source: CaseSource,
        deadline: Date? = nil,
        priority: CasePriority = .normal,
        actions: [CaseActionDraft] = [],
        requirements: [CaseRequirementDraft] = [],
        asset: Asset? = nil,
        person: Person? = nil,
        in context: ModelContext
    ) -> PGCase {
        let pgCase = PGCase(
            title: title,
            descriptionText: descriptionText,
            caseType: caseType,
            source: source,
            status: .draft,
            priority: priority,
            deadline: deadline
        )

        // Link relationships
        pgCase.relatedAsset = asset
        pgCase.relatedPerson = person

        context.insert(pgCase)

        // Create actions from drafts
        for (index, draft) in actions.enumerated() {
            let action = CaseAction(
                title: draft.title,
                descriptionText: draft.descriptionText,
                actionType: draft.actionType,
                orderIndex: index,
                isRequired: draft.isRequired,
                externalURL: draft.externalURL,
                source: draft.source
            )
            action.parentCase = pgCase
            context.insert(action)
        }

        // Create requirements from drafts
        for draft in requirements {
            let requirement = CaseRequirement(
                title: draft.title,
                descriptionText: draft.descriptionText,
                requirementType: draft.requirementType,
                requirementStatus: draft.status,
                isRequired: draft.isRequired,
                confidence: draft.confidence,
                source: draft.source
            )
            requirement.parentCase = pgCase
            context.insert(requirement)
        }

        // Record creation event
        let event = ActivityEvent(
            eventType: .caseCreated,
            title: "Case created",
            detail: "Created \(caseType.displayName) case: \(title)"
        )
        event.parentCase = pgCase
        context.insert(event)

        return pgCase
    }

    // MARK: - Activate

    /// Activate a draft case and generate reminders.
    func activateCase(_ pgCase: PGCase, in context: ModelContext) throws {
        try workflowEngine.transition(pgCase, to: .active, in: context)

        // Make the first action ready
        if let firstAction = pgCase.sortedActions.first {
            firstAction.status = .ready
        }

        // Generate reminders based on deadline
        let reminders = reminderEngine.generateReminders(for: pgCase)
        for reminder in reminders {
            context.insert(reminder)
        }

        // Auto-transition if needed
        if let suggested = workflowEngine.suggestedNextStatus(for: pgCase),
           suggested != pgCase.status {
            try? workflowEngine.transition(pgCase, to: suggested, in: context)
        }
    }

    // MARK: - Complete Action

    /// Mark an action as completed and advance the case workflow.
    func completeAction(
        _ action: CaseAction,
        in context: ModelContext
    ) throws {
        guard let pgCase = action.parentCase else { return }

        action.markCompleted()

        // Record event
        let event = ActivityEvent(
            eventType: .actionCompleted,
            title: "Completed: \(action.title)"
        )
        event.parentCase = pgCase
        context.insert(event)

        // Advance next action to ready
        if let nextAction = pgCase.sortedActions.first(where: { $0.status == .notStarted }) {
            nextAction.status = .ready
        }

        // Check if all required actions are done
        if let suggested = workflowEngine.suggestedNextStatus(for: pgCase) {
            try? workflowEngine.transition(pgCase, to: suggested, in: context)
        }
    }

    // MARK: - Complete Case

    /// Mark a case as completed.
    func completeCase(_ pgCase: PGCase, in context: ModelContext) throws {
        try workflowEngine.transition(pgCase, to: .completed, in: context)
        reminderEngine.cancelAllNotifications(for: pgCase)
    }

    // MARK: - Cancel Case

    func cancelCase(_ pgCase: PGCase, in context: ModelContext) throws {
        try workflowEngine.transition(pgCase, to: .cancelled, in: context)
        reminderEngine.cancelAllNotifications(for: pgCase)
    }

    // MARK: - Link Document

    /// Attach a document to a case and check if it satisfies any requirements.
    func linkDocument(
        _ document: PGDocument,
        to pgCase: PGCase,
        in context: ModelContext
    ) {
        document.parentCase = pgCase

        // Record event
        let event = ActivityEvent(
            eventType: .documentUploaded,
            title: "Document attached: \(document.fileName)"
        )
        event.parentCase = pgCase
        context.insert(event)

        // Check if this document satisfies any pending requirements
        for requirement in pgCase.unsatisfiedRequirements {
            if requirement.requirementType == .document && requirement.linkedDocument == nil {
                // Simple matching — in Phase 2, AI will do smarter matching
                requirement.markProvided(document: document)
                break
            }
        }

        // Re-evaluate workflow
        if let suggested = workflowEngine.suggestedNextStatus(for: pgCase) {
            try? workflowEngine.transition(pgCase, to: suggested, in: context)
        }
    }

    // MARK: - Priority

    /// Get cases sorted by priority for the Home screen.
    func prioritizedCases(_ cases: [PGCase]) -> [PGCase] {
        priorityEngine.prioritize(cases)
    }

    /// Get cases that need immediate attention.
    func casesNeedingAttention(_ cases: [PGCase]) -> [PGCase] {
        priorityEngine.needsAttention(cases)
    }

    /// Get upcoming future cases.
    func upcomingCases(_ cases: [PGCase]) -> [PGCase] {
        priorityEngine.comingUp(cases)
    }
}

// MARK: - Draft Models (for case creation flow)

/// Lightweight struct for building an action before persisting.
struct CaseActionDraft: Identifiable {
    let id = UUID()
    var title: String
    var descriptionText: String = ""
    var actionType: ActionType = .custom
    var isRequired: Bool = true
    var externalURL: String?
    var source: String?
}

/// Lightweight struct for building a requirement before persisting.
struct CaseRequirementDraft: Identifiable {
    let id = UUID()
    var title: String
    var descriptionText: String = ""
    var requirementType: RequirementType = .document
    var status: RequirementStatus = .missing
    var isRequired: Bool = true
    var confidence: Double = 1.0
    var source: String?
}
