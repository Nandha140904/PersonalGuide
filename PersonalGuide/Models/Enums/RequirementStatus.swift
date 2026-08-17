// MARK: - RequirementStatus.swift
// PersonalGuide

import Foundation

/// Status tracking for a case requirement (document, info, payment, etc.).
enum RequirementStatus: String, Codable, CaseIterable, Identifiable {
    case unknown     = "UNKNOWN"
    case missing     = "MISSING"
    case requested   = "REQUESTED"
    case provided    = "PROVIDED"
    case verified    = "VERIFIED"
    case rejected    = "REJECTED"
    case notRequired = "NOT_REQUIRED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unknown:     return "Unknown"
        case .missing:     return "Missing"
        case .requested:   return "Requested"
        case .provided:    return "Provided"
        case .verified:    return "Verified"
        case .rejected:    return "Rejected"
        case .notRequired: return "Not Required"
        }
    }

    /// Whether this requirement is satisfied (provided, verified, or not needed).
    var isSatisfied: Bool {
        switch self {
        case .provided, .verified, .notRequired:
            return true
        default:
            return false
        }
    }

    /// Whether the user needs to take action on this requirement.
    var needsUserAction: Bool {
        switch self {
        case .unknown, .missing, .rejected:
            return true
        default:
            return false
        }
    }

    var iconName: String {
        switch self {
        case .unknown:     return "questionmark.circle"
        case .missing:     return "circle"
        case .requested:   return "arrow.down.circle"
        case .provided:    return "checkmark.circle.fill"
        case .verified:    return "checkmark.seal.fill"
        case .rejected:    return "xmark.circle.fill"
        case .notRequired: return "minus.circle"
        }
    }
}

// MARK: - RequirementType

/// The kind of thing required to proceed with a case.
enum RequirementType: String, Codable, CaseIterable, Identifiable {
    case document           = "DOCUMENT"
    case personalInformation = "PERSONAL_INFORMATION"
    case payment            = "PAYMENT"
    case eligibility        = "ELIGIBILITY"
    case externalAction     = "EXTERNAL_ACTION"
    case approval           = "APPROVAL"
    case confirmation       = "CONFIRMATION"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .document:            return "Document"
        case .personalInformation: return "Information"
        case .payment:             return "Payment"
        case .eligibility:         return "Eligibility"
        case .externalAction:      return "External Action"
        case .approval:            return "Approval"
        case .confirmation:        return "Confirmation"
        }
    }

    var iconName: String {
        switch self {
        case .document:            return "doc.fill"
        case .personalInformation: return "person.text.rectangle"
        case .payment:             return "indianrupeesign.circle"
        case .eligibility:         return "person.badge.shield.checkmark"
        case .externalAction:      return "arrow.up.forward.square"
        case .approval:            return "signature"
        case .confirmation:        return "hand.thumbsup.fill"
        }
    }
}
