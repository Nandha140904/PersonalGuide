// MARK: - CaseStatus.swift
// PersonalGuide
//
// Deterministic case lifecycle states.
// Transitions are validated by WorkflowEngine — not arbitrary.

import Foundation

/// Represents the lifecycle status of a life-admin case.
///
/// Status transitions follow a validated state machine (see `WorkflowEngine`).
/// AI cannot change status without user confirmation for consequential transitions.
enum CaseStatus: String, Codable, CaseIterable, Identifiable {
    case draft            = "DRAFT"
    case active           = "ACTIVE"
    case needsInformation = "NEEDS_INFORMATION"
    case readyForAction   = "READY_FOR_ACTION"
    case inProgress       = "IN_PROGRESS"
    case waiting          = "WAITING"
    case blocked          = "BLOCKED"
    case completed        = "COMPLETED"
    case cancelled        = "CANCELLED"
    case archived         = "ARCHIVED"

    var id: String { rawValue }

    /// Human-readable display label.
    var displayName: String {
        switch self {
        case .draft:            return "Draft"
        case .active:           return "Active"
        case .needsInformation: return "Needs Information"
        case .readyForAction:   return "Ready for Action"
        case .inProgress:       return "In Progress"
        case .waiting:          return "Waiting"
        case .blocked:          return "Blocked"
        case .completed:        return "Completed"
        case .cancelled:        return "Cancelled"
        case .archived:         return "Archived"
        }
    }

    /// Whether this status represents an "open" (actionable) case.
    var isOpen: Bool {
        switch self {
        case .draft, .active, .needsInformation, .readyForAction, .inProgress, .waiting, .blocked:
            return true
        case .completed, .cancelled, .archived:
            return false
        }
    }

    /// Whether the user can take direct action on a case in this status.
    var isActionable: Bool {
        switch self {
        case .active, .readyForAction, .inProgress:
            return true
        default:
            return false
        }
    }

    /// SF Symbol name for status icon.
    var iconName: String {
        switch self {
        case .draft:            return "doc.badge.ellipsis"
        case .active:           return "bolt.circle.fill"
        case .needsInformation: return "questionmark.circle.fill"
        case .readyForAction:   return "checkmark.circle"
        case .inProgress:       return "arrow.forward.circle.fill"
        case .waiting:          return "clock.fill"
        case .blocked:          return "exclamationmark.triangle.fill"
        case .completed:        return "checkmark.seal.fill"
        case .cancelled:        return "xmark.circle.fill"
        case .archived:         return "archivebox.fill"
        }
    }
}
