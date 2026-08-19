// MARK: - AIModels.swift
// PersonalGuide
//
// Structured models and confidence wrappers for all AI-derived analysis.
// Adheres strictly to the spec rule: Every extracted field has an explicit confidence rating.

import Foundation

// MARK: - Confidence Wrapper

public struct ConfidentField<T: Sendable>: Sendable {
    public let value: T
    public let confidence: Double // 0.0 to 1.0
    public let sourceText: String?

    public init(value: T, confidence: Double, sourceText: String? = nil) {
        self.value = value
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.sourceText = sourceText
    }

    /// Whether this field is considered high confidence (>= 0.8) and can be auto-accepted.
    public var isHighConfidence: Bool {
        confidence >= 0.80
    }
}

// MARK: - Classification Result

public struct AIClassificationResult: Sendable {
    public let caseType: CaseType
    public let documentType: DocumentType
    public let confidence: Double
    public let rationale: String

    public init(caseType: CaseType, documentType: DocumentType, confidence: Double, rationale: String) {
        self.caseType = caseType
        self.documentType = documentType
        self.confidence = confidence
        self.rationale = rationale
    }
}

// MARK: - Document Extraction Result

public struct AIExtractionResult: Sendable {
    public var counterparty: ConfidentField<String>?       // Merchant, Insurer, Landlord, Gov Agency
    public var referenceNumber: ConfidentField<String>?     // Policy #, Order ID, Invoice #, Account #
    public var monetaryAmount: ConfidentField<Decimal>?     // Total due, refund amount, policy value
    public var currencyCode: String                         // USD, EUR, INR, GBP
    public var keyDates: [String: ConfidentField<Date>]     // "deadline", "renewal", "expiry", "issue"
    public var structuredMetadata: [String: String]        // Any custom key-values discovered
    public var summary: String
    public var confidence: Double

    public init(
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

public struct AIPlannedAction: Sendable, Identifiable {
    public var id = UUID()
    public let title: String
    public let descriptionText: String
    public let actionType: ActionType
    public let orderIndex: Int
    public let isRequired: Bool
    public let deadline: Date?
    public let externalURL: String?
    public let confidence: Double

    public init(
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

public struct AIPlannedRequirement: Sendable, Identifiable {
    public var id = UUID()
    public let title: String
    public let descriptionText: String
    public let requirementType: RequirementType
    public let isRequired: Bool
    public let confidence: Double

    public init(
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

public struct AICasePlan: Sendable {
    public let title: String
    public let descriptionText: String
    public let caseType: CaseType
    public let suggestedPriority: CasePriority
    public let suggestedDeadline: Date?
    public let actions: [AIPlannedAction]
    public let requirements: [AIPlannedRequirement]
    public let extractedFields: AIExtractionResult
    public let confidence: Double

    public init(
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
