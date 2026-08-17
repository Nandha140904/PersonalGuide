// MARK: - CaseType.swift
// PersonalGuide
//
// The five core MVP case types, plus Generic for anything else.

import Foundation

/// The type of life-admin case.
///
/// MVP supports five core types. The Generic type serves as a catch-all
/// for any admin task that doesn't fit the predefined categories.
enum CaseType: String, Codable, CaseIterable, Identifiable {
    case purchaseReturn       = "PURCHASE_RETURN"
    case subscriptionBill     = "SUBSCRIPTION_BILL"
    case documentRenewal      = "DOCUMENT_RENEWAL"
    case insuranceWarranty    = "INSURANCE_WARRANTY"
    case genericLifeAdmin     = "GENERIC_LIFE_ADMIN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .purchaseReturn:    return "Purchase / Return"
        case .subscriptionBill:  return "Subscription / Bill"
        case .documentRenewal:   return "Document Renewal"
        case .insuranceWarranty: return "Insurance / Warranty"
        case .genericLifeAdmin:  return "Life Admin"
        }
    }

    /// Short label for cards and badges.
    var shortLabel: String {
        switch self {
        case .purchaseReturn:    return "Return"
        case .subscriptionBill:  return "Bill"
        case .documentRenewal:   return "Renewal"
        case .insuranceWarranty: return "Insurance"
        case .genericLifeAdmin:  return "Admin"
        }
    }

    var iconName: String {
        switch self {
        case .purchaseReturn:    return "bag.fill"
        case .subscriptionBill:  return "creditcard.fill"
        case .documentRenewal:   return "doc.text.fill"
        case .insuranceWarranty: return "shield.checkered"
        case .genericLifeAdmin:  return "folder.fill"
        }
    }

    /// Suggested category for library filtering.
    var defaultCategory: String {
        switch self {
        case .purchaseReturn:    return "Purchases"
        case .subscriptionBill:  return "Bills"
        case .documentRenewal:   return "Documents"
        case .insuranceWarranty: return "Insurance"
        case .genericLifeAdmin:  return "General"
        }
    }
}
