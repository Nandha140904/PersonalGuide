// MARK: - WorkflowEngine.swift
// PersonalGuide
//
// Deterministic state machine for case lifecycle transitions.
// AI cannot change status arbitrarily — transitions must be valid.
// Every transition is logged as an ActivityEvent for audit.

import Foundation
import SwiftData

/// Validates and executes case status transitions.
///
/// This is the gatekeeper for case lifecycle changes. It enforces
/// a strict state machine to prevent invalid transitions and ensures
/// every change is recorded in the activity timeline.
@Observable
final class WorkflowEngine {

    // MARK: - Transition Map

    /// Defines all valid status transitions.
    /// Key = current status, Value = set of allowed next statuses.
    private static let validTransitions: [CaseStatus: Set<CaseStatus>] = [
        .draft:            [.active, .cancelled],
        .active:           [.needsInformation, .readyForAction, .inProgress, .waiting, .blocked, .cancelled],
        .needsInformation: [.active, .readyForAction, .cancelled],
        .readyForAction:   [.inProgress, .needsInformation, .cancelled],
        .inProgress:       [.waiting, .blocked, .completed, .needsInformation, .cancelled],
        .waiting:          [.inProgress, .active, .needsInformation, .cancelled],
        .blocked:          [.inProgress, .active, .needsInformation, .cancelled],
        .completed:        [.archived, .active],  // Allow reopening
        .cancelled:        [.active, .archived],   // Allow reactivation
        .archived:         [.active],              // Allow unarchiving
    ]

    // MARK: - Validation

    /// Check if a transition from one status to another is valid.
    func canTransition(from current: CaseStatus, to target: CaseStatus) -> Bool {
        guard current != target else { return false } // No-op transitions not allowed
        return Self.validTransitions[current]?.contains(target) ?? false
    }

    /// Returns all valid next statuses from the current status.
    func validNextStatuses(from current: CaseStatus) -> [CaseStatus] {
        let allowed = Self.validTransitions[current] ?? []
        return CaseStatus.allCases.filter { allowed.contains($0) }
    }

    // MARK: - Execution

    /// Attempt to transition a case to a new status.
    ///
    /// - Parameters:
    ///   - pgCase: The case to transition.
    ///   - newStatus: The target status.
    ///   - context: The SwiftData model context for creating activity events.
    ///   - detail: Optional detail string for the activity event.
    /// - Returns: `true` if the transition was successful.
    /// - Throws: `WorkflowError` if the transition is invalid.
    @discardableResult
    func transition(
        _ pgCase: PGCase,
        to newStatus: CaseStatus,
        in context: ModelContext,
        detail: String? = nil
    ) throws -> Bool {
        let currentStatus = pgCase.status

        guard canTransition(from: currentStatus, to: newStatus) else {
            throw WorkflowError.invalidTransition(from: currentStatus, to: newStatus)
        }

        // Execute the transition
        let previousStatus = currentStatus
        pgCase.status = newStatus

        // Record the event
        let event = ActivityEvent(
            eventType: eventType(for: newStatus),
            title: "Status changed to \(newStatus.displayName)",
            detail: detail ?? "Changed from \(previousStatus.displayName) to \(newStatus.displayName)"
        )
        event.parentCase = pgCase
        context.insert(event)

        // Handle completion side-effects
        if newStatus == .completed {
            pgCase.completedAt = .now
        }

        return true
    }

    // MARK: - Smart Transitions

    /// Automatically determine the best next status based on case state.
    ///
    /// This is a convenience that evaluates the case's current requirements
    /// and actions to suggest the most logical next status.
    func suggestedNextStatus(for pgCase: PGCase) -> CaseStatus? {
        let current = pgCase.status

        switch current {
        case .draft:
            return .active

        case .active:
            if !pgCase.allRequirementsMet {
                return .needsInformation
            } else if pgCase.nextAction != nil {
                return .readyForAction
            }
            return nil

        case .needsInformation:
            if pgCase.allRequirementsMet {
                return .readyForAction
            }
            return nil

        case .readyForAction:
            return .inProgress

        case .inProgress:
            let progress = pgCase.completionProgress
            if progress.completed >= progress.total && progress.total > 0 {
                return .completed
            }
            return nil

        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func eventType(for status: CaseStatus) -> ActivityEventType {
        switch status {
        case .completed:  return .caseCompleted
        case .cancelled:  return .caseCancelled
        default:          return .statusChanged
        }
    }
}

// MARK: - WorkflowError

enum WorkflowError: LocalizedError {
    case invalidTransition(from: CaseStatus, to: CaseStatus)

    var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let to):
            return "Cannot transition from \(from.displayName) to \(to.displayName)."
        }
    }
}
