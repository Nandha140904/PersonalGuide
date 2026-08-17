// MARK: - PriorityEngine.swift
// PersonalGuide
//
// Deterministic case prioritization for the Home screen.
// AI can provide contextual recommendations but is NOT the sole ranking mechanism.
// Priority is computed from: deadline, actions needed, consequences, user preference.

import Foundation

/// Computes deterministic priority scores for cases to power Home screen ordering.
///
/// The scoring formula:
/// ```
/// priority_score = deadline_score + action_score + consequence_score + user_priority_score
/// ```
///
/// Each component is deterministic and auditable — no LLM in the loop.
@Observable
final class PriorityEngine {

    // MARK: - Scoring

    /// Compute a composite priority score for a case (higher = more urgent).
    func score(for pgCase: PGCase) -> Double {
        let deadline   = deadlineScore(for: pgCase)
        let action     = actionScore(for: pgCase)
        let consequence = consequenceScore(for: pgCase)
        let userPriority = userPriorityScore(for: pgCase)
        let statusBonus = statusBonus(for: pgCase)

        return deadline + action + consequence + userPriority + statusBonus
    }

    /// Sort cases by priority score, highest first.
    func prioritize(_ cases: [PGCase]) -> [PGCase] {
        cases
            .filter { $0.status.isOpen }
            .sorted { score(for: $0) > score(for: $1) }
    }

    // MARK: - Component Scores

    /// Deadline proximity score (0–50 points).
    /// Closer deadlines score higher. Overdue cases get maximum score.
    func deadlineScore(for pgCase: PGCase) -> Double {
        guard let daysLeft = pgCase.daysUntilDeadline else {
            return 5 // No deadline — low baseline
        }

        if daysLeft < 0 {
            return 50 // Overdue — maximum urgency
        }

        switch daysLeft {
        case 0:       return 45
        case 1:       return 40
        case 2...3:   return 35
        case 4...7:   return 25
        case 8...14:  return 15
        case 15...30: return 10
        default:      return 5
        }
    }

    /// Action readiness score (0–20 points).
    /// Cases with actionable next steps score higher than those waiting or blocked.
    func actionScore(for pgCase: PGCase) -> Double {
        if pgCase.status == .readyForAction { return 20 }
        if pgCase.nextAction?.status.isActionable == true { return 15 }
        if pgCase.status == .needsInformation { return 12 }
        if pgCase.status == .blocked { return 8 }
        if pgCase.status == .waiting { return 5 }
        return 3
    }

    /// Consequence score based on case type and impact (0–15 points).
    /// Insurance/document renewals have higher consequences than generic admin.
    func consequenceScore(for pgCase: PGCase) -> Double {
        switch pgCase.caseType {
        case .insuranceWarranty: return 15
        case .documentRenewal:   return 12
        case .subscriptionBill:  return 10
        case .purchaseReturn:    return 8
        case .genericLifeAdmin:  return 5
        }
    }

    /// User-set priority score (0–15 points).
    func userPriorityScore(for pgCase: PGCase) -> Double {
        Double(pgCase.priority.weight) * 3.0 // 3, 6, 9, 12, 15
    }

    /// Bonus for cases in certain active statuses.
    private func statusBonus(for pgCase: PGCase) -> Double {
        switch pgCase.status {
        case .inProgress:       return 5
        case .needsInformation: return 3
        case .active:           return 2
        default:                return 0
        }
    }

    // MARK: - Filtering

    /// Cases that "need attention" — overdue, blocked, or actionable with close deadlines.
    func needsAttention(_ cases: [PGCase]) -> [PGCase] {
        prioritize(cases).filter { pgCase in
            pgCase.isOverdue ||
            pgCase.status == .blocked ||
            (pgCase.status.isActionable && (pgCase.daysUntilDeadline ?? 999) <= 7)
        }
    }

    /// Cases "coming up" — future items not currently actionable.
    func comingUp(_ cases: [PGCase]) -> [PGCase] {
        cases
            .filter { $0.status.isOpen && !$0.status.isActionable }
            .filter { ($0.daysUntilDeadline ?? 999) > 7 }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }
}
