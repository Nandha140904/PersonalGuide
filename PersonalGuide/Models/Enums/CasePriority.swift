// MARK: - CasePriority.swift
// PersonalGuide
//
// Priority levels derived from deadline, financial impact, consequences,
// user preference, case type, and confidence. Never LLM-decided alone.

import Foundation

/// Priority level for a life-admin case.
///
/// Priority is computed deterministically by `PriorityEngine` using:
/// deadline proximity, financial impact, consequences, user preference,
/// case type, and confidence score.
enum CasePriority: String, Codable, CaseIterable, Comparable, Identifiable {
    case low      = "LOW"
    case normal   = "NORMAL"
    case high     = "HIGH"
    case urgent   = "URGENT"
    case critical = "CRITICAL"

    var id: String { rawValue }

    /// Numeric weight for deterministic scoring.
    var weight: Int {
        switch self {
        case .low:      return 1
        case .normal:   return 2
        case .high:     return 3
        case .urgent:   return 4
        case .critical: return 5
        }
    }

    var displayName: String {
        switch self {
        case .low:      return "Low"
        case .normal:   return "Normal"
        case .high:     return "High"
        case .urgent:   return "Urgent"
        case .critical: return "Critical"
        }
    }

    var iconName: String {
        switch self {
        case .low:      return "arrow.down"
        case .normal:   return "minus"
        case .high:     return "arrow.up"
        case .urgent:   return "exclamationmark"
        case .critical: return "exclamationmark.2"
        }
    }

    static func < (lhs: CasePriority, rhs: CasePriority) -> Bool {
        lhs.weight < rhs.weight
    }
}
