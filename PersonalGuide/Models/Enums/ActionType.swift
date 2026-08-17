// MARK: - ActionType.swift
// PersonalGuide

import Foundation

/// The kind of action the user needs to perform.
///
/// Action types help the UI present contextual affordances —
/// e.g., an `openURL` action shows a link button, a `call` action
/// shows a phone button, an `upload` action shows a document picker.
enum ActionType: String, Codable, CaseIterable, Identifiable {
    case read      = "READ"
    case upload    = "UPLOAD"
    case fillForm  = "FILL_FORM"
    case openURL   = "OPEN_URL"
    case call      = "CALL"
    case email     = "EMAIL"
    case pay       = "PAY"
    case compare   = "COMPARE"
    case verify    = "VERIFY"
    case confirm   = "CONFIRM"
    case wait      = "WAIT"
    case custom    = "CUSTOM"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .read:     return "Read"
        case .upload:   return "Upload"
        case .fillForm: return "Fill Form"
        case .openURL:  return "Open Link"
        case .call:     return "Call"
        case .email:    return "Email"
        case .pay:      return "Pay"
        case .compare:  return "Compare"
        case .verify:   return "Verify"
        case .confirm:  return "Confirm"
        case .wait:     return "Wait"
        case .custom:   return "Action"
        }
    }

    var iconName: String {
        switch self {
        case .read:     return "book"
        case .upload:   return "arrow.up.doc"
        case .fillForm: return "doc.plaintext"
        case .openURL:  return "safari"
        case .call:     return "phone"
        case .email:    return "envelope"
        case .pay:      return "indianrupeesign.circle"
        case .compare:  return "arrow.left.arrow.right"
        case .verify:   return "checkmark.shield"
        case .confirm:  return "hand.thumbsup"
        case .wait:     return "hourglass"
        case .custom:   return "star"
        }
    }

    /// Whether this action type involves an external interaction (URL, phone, email).
    var isExternalAction: Bool {
        switch self {
        case .openURL, .call, .email, .pay:
            return true
        default:
            return false
        }
    }
}
