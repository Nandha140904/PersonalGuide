// MARK: - ActionStatus.swift
// PersonalGuide

import Foundation

/// Lifecycle status for a single action step within a case.
enum ActionStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "NOT_STARTED"
    case ready      = "READY"
    case inProgress = "IN_PROGRESS"
    case waiting    = "WAITING"
    case blocked    = "BLOCKED"
    case completed  = "COMPLETED"
    case skipped    = "SKIPPED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .ready:      return "Ready"
        case .inProgress: return "In Progress"
        case .waiting:    return "Waiting"
        case .blocked:    return "Blocked"
        case .completed:  return "Completed"
        case .skipped:    return "Skipped"
        }
    }

    /// Whether this action is considered "done" (completed or intentionally skipped).
    var isDone: Bool {
        self == .completed || self == .skipped
    }

    /// Whether the user can currently work on this action.
    var isActionable: Bool {
        self == .ready || self == .inProgress
    }

    var iconName: String {
        switch self {
        case .notStarted: return "circle"
        case .ready:      return "circle.dotted"
        case .inProgress: return "arrow.forward.circle"
        case .waiting:    return "clock"
        case .blocked:    return "exclamationmark.triangle"
        case .completed:  return "checkmark.circle.fill"
        case .skipped:    return "forward.fill"
        }
    }
}
