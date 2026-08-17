// MARK: - CaseRequirement.swift
// PersonalGuide
//
// Something the user needs to provide or satisfy before the case
// can proceed — a document, personal info, payment, eligibility, etc.

import Foundation
import SwiftData

@Model
final class CaseRequirement {

    var id: UUID
    var title: String
    var descriptionText: String
    var isRequired: Bool

    // MARK: - Classification

    var requirementTypeRaw: String
    var requirementStatusRaw: String

    // MARK: - AI Confidence

    /// How confident the system is that this requirement is needed (0.0–1.0).
    var confidence: Double

    /// Source that identified this requirement (e.g., "ai_planner", "template", "user").
    var source: String?

    /// Arbitrary metadata (JSON-encoded).
    var metadataJSON: String?

    // MARK: - Relationships

    var parentCase: PGCase?

    /// If this requirement is a document, the linked document.
    var linkedDocument: PGDocument?

    // MARK: - Init

    init(
        title: String,
        descriptionText: String = "",
        requirementType: RequirementType = .document,
        requirementStatus: RequirementStatus = .missing,
        isRequired: Bool = true,
        confidence: Double = 1.0,
        source: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.requirementTypeRaw = requirementType.rawValue
        self.requirementStatusRaw = requirementStatus.rawValue
        self.isRequired = isRequired
        self.confidence = confidence
        self.source = source
    }

    // MARK: - Computed

    var requirementType: RequirementType {
        get { RequirementType(rawValue: requirementTypeRaw) ?? .document }
        set { requirementTypeRaw = newValue.rawValue }
    }

    var requirementStatus: RequirementStatus {
        get { RequirementStatus(rawValue: requirementStatusRaw) ?? .missing }
        set { requirementStatusRaw = newValue.rawValue }
    }

    /// Mark as provided (user has supplied the required item).
    func markProvided(document: PGDocument? = nil) {
        requirementStatus = .provided
        linkedDocument = document
    }

    /// Mark as verified (system has confirmed the provided item is valid).
    func markVerified() {
        requirementStatus = .verified
    }
}
