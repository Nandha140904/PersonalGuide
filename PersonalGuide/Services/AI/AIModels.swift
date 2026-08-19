// MARK: - AIModels.swift
// PersonalGuide
//
// Structured models and confidence wrappers for all AI-derived analysis.
// Adheres strictly to the spec rule: Every extracted field has an explicit confidence rating.

import Foundation

// MARK: - Confidence Wrapper

struct ConfidentField<T: Sendable>: Sendable {
    let value: T
    let confidence: Double // 0.0 to 1.0
    let sourceText: String?

    init(value: T, confidence: Double, sourceText: String? = nil) {
        self.value = value
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.sourceText = sourceText
    }

    /// Whether this field is considered high confidence (>= 0.8) and can be auto-accepted.
    var isHighConfidence: Bool {
        confidence >= 0.80
    }
}

// MARK: - Classification Result

struct AIClassificationResult: Sendable {
    let caseType: CaseType
    let documentType: DocumentType
    let confidence: Double
    let rationale: String

    init(caseType: CaseType, documentType: DocumentType, confidence: Double, rationale: String) {
        self.caseType = caseType
        self.documentType = documentType
        self.confidence = confidence
        self.rationale = rationale
    }
}

// MARK: - Document Extraction Result

struct AIExtractionResult: Sendable {
    var counterparty: ConfidentField<String>?       // Merchant, Insurer, Landlord, Gov Agency
    var referenceNumber: ConfidentField<String>?     // Policy #, Order ID, Invoice #, Account #
    var monetaryAmount: ConfidentField<Decimal>?     // Total due, refund amount, policy value
    var currencyCode: String                         // USD, EUR, INR, GBP
    var keyDates: [String: ConfidentField<Date>]     // "deadline", "renewal", "expiry", "issue"
    var structuredMetadata: [String: String]        // Any custom key-values discovered
    var summary: String
    var confidence: Double

    init(
        counterparty: ConfidentField<String>? = nil,
        referenceNumber: ConfidentField<String>? = nil,
        monetaryAmount: ConfidentField<Decimal>? = nil,
        currencyCode: String = "USD",
        keyDates: [String: ConfidentField<Date>] = [:],
        structuredMetadata: [String: String] = [:],
        summary: String = "",
        confidence: Double = 1.0
    ) {
        self.counterparty = counterparty
        self.referenceNumber = referenceNumber
        self.monetaryAmount = monetaryAmount
        self.currencyCode = currencyCode
        self.keyDates = keyDates
        self.structuredMetadata = structuredMetadata
        self.summary = summary
        self.confidence = confidence
    }
}

// MARK: - Planned Actions & Requirements

struct AIPlannedAction: Sendable, Identifiable {
    var id = UUID()
    let title: String
    let descriptionText: String
    let actionType: ActionType
    let orderIndex: Int
    let isRequired: Bool
    let deadline: Date?
    let externalURL: String?
    let confidence: Double

    init(
        title: String,
        descriptionText: String = "",
        actionType: ActionType = .custom,
        orderIndex: Int = 0,
        isRequired: Bool = true,
        deadline: Date? = nil,
        externalURL: String? = nil,
        confidence: Double = 0.9
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.actionType = actionType
        self.orderIndex = orderIndex
        self.isRequired = isRequired
        self.deadline = deadline
        self.externalURL = externalURL
        self.confidence = confidence
    }
}

struct AIPlannedRequirement: Sendable, Identifiable {
    var id = UUID()
    let title: String
    let descriptionText: String
    let requirementType: RequirementType
    let isRequired: Bool
    let confidence: Double

    init(
        title: String,
        descriptionText: String = "",
        requirementType: RequirementType = .document,
        isRequired: Bool = true,
        confidence: Double = 0.9
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.requirementType = requirementType
        self.isRequired = isRequired
        self.confidence = confidence
    }
}

// MARK: - Case Plan Result

struct AICasePlan: Sendable {
    let title: String
    let descriptionText: String
    let caseType: CaseType
    let suggestedPriority: CasePriority
    let suggestedDeadline: Date?
    let actions: [AIPlannedAction]
    let requirements: [AIPlannedRequirement]
    let extractedFields: AIExtractionResult
    let confidence: Double

    init(
        title: String,
        descriptionText: String,
        caseType: CaseType,
        suggestedPriority: CasePriority = .normal,
        suggestedDeadline: Date? = nil,
        actions: [AIPlannedAction] = [],
        requirements: [AIPlannedRequirement] = [],
        extractedFields: AIExtractionResult = AIExtractionResult(),
        confidence: Double = 0.85
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.caseType = caseType
        self.suggestedPriority = suggestedPriority
        self.suggestedDeadline = suggestedDeadline
        self.actions = actions
        self.requirements = requirements
        self.extractedFields = extractedFields
        self.confidence = confidence
    }
}
