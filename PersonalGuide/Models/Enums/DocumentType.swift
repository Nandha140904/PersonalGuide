// MARK: - DocumentType.swift
// PersonalGuide

import Foundation

/// Classification of uploaded documents.
///
/// Used by the AI Classifier to categorize documents after upload.
/// Confidence is tracked separately — this is the classified result.
enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case receipt           = "RECEIPT"
    case invoice           = "INVOICE"
    case bill              = "BILL"
    case policy            = "POLICY"
    case certificate       = "CERTIFICATE"
    case idDocument        = "ID_DOCUMENT"
    case warranty          = "WARRANTY"
    case correspondence    = "CORRESPONDENCE"
    case applicationForm   = "APPLICATION_FORM"
    case proof             = "PROOF"
    case report            = "REPORT"
    case agreement         = "AGREEMENT"
    case other             = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receipt:         return "Receipt"
        case .invoice:         return "Invoice"
        case .bill:            return "Bill"
        case .policy:          return "Policy"
        case .certificate:     return "Certificate"
        case .idDocument:      return "ID Document"
        case .warranty:        return "Warranty"
        case .correspondence:  return "Correspondence"
        case .applicationForm: return "Application Form"
        case .proof:           return "Proof"
        case .report:          return "Report"
        case .agreement:       return "Agreement"
        case .other:           return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .receipt:         return "receipt"
        case .invoice:         return "doc.text"
        case .bill:            return "banknote"
        case .policy:          return "shield.lefthalf.filled"
        case .certificate:     return "rosette"
        case .idDocument:      return "person.crop.rectangle"
        case .warranty:        return "checkmark.shield"
        case .correspondence:  return "envelope"
        case .applicationForm: return "doc.richtext"
        case .proof:           return "doc.badge.plus"
        case .report:          return "chart.bar.doc.horizontal"
        case .agreement:       return "signature"
        case .other:           return "doc"
        }
    }
}

// MARK: - ActivityEventType

/// Types of events recorded in the case activity timeline.
enum ActivityEventType: String, Codable, CaseIterable {
    case caseCreated           = "CASE_CREATED"
    case caseUpdated           = "CASE_UPDATED"
    case statusChanged         = "STATUS_CHANGED"
    case actionCompleted       = "ACTION_COMPLETED"
    case actionStarted         = "ACTION_STARTED"
    case requirementProvided   = "REQUIREMENT_PROVIDED"
    case documentUploaded      = "DOCUMENT_UPLOADED"
    case documentProcessed     = "DOCUMENT_PROCESSED"
    case aiExtraction          = "AI_EXTRACTION"
    case userConfirmation      = "USER_CONFIRMATION"
    case reminderTriggered     = "REMINDER_TRIGGERED"
    case caseCompleted         = "CASE_COMPLETED"
    case caseCancelled         = "CASE_CANCELLED"
    case noteAdded             = "NOTE_ADDED"

    var displayName: String {
        switch self {
        case .caseCreated:         return "Case created"
        case .caseUpdated:         return "Case updated"
        case .statusChanged:       return "Status changed"
        case .actionCompleted:     return "Action completed"
        case .actionStarted:       return "Action started"
        case .requirementProvided: return "Requirement provided"
        case .documentUploaded:    return "Document uploaded"
        case .documentProcessed:   return "Document processed"
        case .aiExtraction:        return "Information extracted"
        case .userConfirmation:    return "Confirmed by you"
        case .reminderTriggered:   return "Reminder sent"
        case .caseCompleted:       return "Case completed"
        case .caseCancelled:       return "Case cancelled"
        case .noteAdded:           return "Note added"
        }
    }

    var iconName: String {
        switch self {
        case .caseCreated:         return "plus.circle"
        case .caseUpdated:         return "pencil.circle"
        case .statusChanged:       return "arrow.triangle.2.circlepath"
        case .actionCompleted:     return "checkmark.circle.fill"
        case .actionStarted:       return "play.circle"
        case .requirementProvided: return "doc.badge.plus"
        case .documentUploaded:    return "arrow.up.doc"
        case .documentProcessed:   return "doc.text.magnifyingglass"
        case .aiExtraction:        return "sparkles"
        case .userConfirmation:    return "hand.thumbsup"
        case .reminderTriggered:   return "bell"
        case .caseCompleted:       return "checkmark.seal.fill"
        case .caseCancelled:       return "xmark.circle"
        case .noteAdded:           return "note.text"
        }
    }
}

// MARK: - ReminderType

/// Types of reminders, per spec section 16.
enum ReminderType: String, Codable, CaseIterable {
    case upcoming       = "UPCOMING"
    case actionRequired = "ACTION_REQUIRED"
    case deadline       = "DEADLINE"
    case followUp       = "FOLLOW_UP"
    case waiting        = "WAITING"
    case custom         = "CUSTOM"

    var displayName: String {
        switch self {
        case .upcoming:       return "Upcoming"
        case .actionRequired: return "Action Required"
        case .deadline:       return "Deadline"
        case .followUp:       return "Follow Up"
        case .waiting:        return "Waiting"
        case .custom:         return "Custom"
        }
    }
}

// MARK: - ReminderStatus

enum ReminderStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case sent      = "SENT"
    case dismissed = "DISMISSED"
    case cancelled = "CANCELLED"
}

// MARK: - CaseSource

/// How a case was originally created.
enum CaseSource: String, Codable {
    case naturalLanguage = "NATURAL_LANGUAGE"
    case documentScan    = "DOCUMENT_SCAN"
    case manualEntry     = "MANUAL_ENTRY"
    case imported        = "IMPORTED"
}

// MARK: - AssetType

/// Types of real-world assets that connect multiple admin items.
enum AssetType: String, Codable, CaseIterable, Identifiable {
    case vehicle    = "VEHICLE"
    case phone      = "PHONE"
    case laptop     = "LAPTOP"
    case home       = "HOME"
    case appliance  = "APPLIANCE"
    case electronics = "ELECTRONICS"
    case other      = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vehicle:     return "Vehicle"
        case .phone:       return "Phone"
        case .laptop:      return "Laptop"
        case .home:        return "Home"
        case .appliance:   return "Appliance"
        case .electronics: return "Electronics"
        case .other:       return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .vehicle:     return "car.fill"
        case .phone:       return "iphone"
        case .laptop:      return "laptopcomputer"
        case .home:        return "house.fill"
        case .appliance:   return "washer.fill"
        case .electronics: return "desktopcomputer"
        case .other:       return "cube.fill"
        }
    }
}
