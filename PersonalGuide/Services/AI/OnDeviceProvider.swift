// MARK: - OnDeviceProvider.swift
// PersonalGuide
//
// 100% private, offline AI provider using Apple's NaturalLanguage framework and heuristics.
// Ensures Personal Guide is fully functional even with zero cloud connection or API keys.

import Foundation
import NaturalLanguage

final class OnDeviceProvider: AIProvider {

    let providerName = "On-Device (Apple NL)"
    var isConfigured: Bool { true }

    init() {}

    // MARK: - Classification

    func classify(text: String) async throws -> AIClassificationResult {
        let lower = text.lowercased()

        if lower.contains("return") || lower.contains("refund") || lower.contains("delivered") || lower.contains("order #") || lower.contains("shipped") {
            return AIClassificationResult(
                caseType: .purchaseReturn,
                documentType: .receipt,
                confidence: 0.85,
                rationale: "Detected order, delivery, or return keywords."
            )
        } else if lower.contains("policy") || lower.contains("insurance") || lower.contains("coverage") || lower.contains("claim") || lower.contains("premium") {
            return AIClassificationResult(
                caseType: .insuranceWarranty,
                documentType: .policy,
                confidence: 0.88,
                rationale: "Detected insurance policy or claim terms."
            )
        } else if lower.contains("passport") || lower.contains("license") || lower.contains("expire") || lower.contains("expiry") || lower.contains("renewal") {
            return AIClassificationResult(
                caseType: .documentRenewal,
                documentType: .idDocument,
                confidence: 0.82,
                rationale: "Detected identity or renewal document terms."
            )
        } else if lower.contains("subscription") || lower.contains("invoice") || lower.contains("bill") || lower.contains("amount due") || lower.contains("due date") {
            return AIClassificationResult(
                caseType: .subscriptionBill,
                documentType: .bill,
                confidence: 0.85,
                rationale: "Detected recurring billing or invoice details."
            )
        }

        return AIClassificationResult(
            caseType: .genericLifeAdmin,
            documentType: .other,
            confidence: 0.50,
            rationale: "General administrative matter."
        )
    }

    // MARK: - Extraction

    func extract(text: String, expectedType: DocumentType?) async throws -> AIExtractionResult {
        var result = AIExtractionResult()

        // 1. Counterparty extraction using Apple NLTagger (Organization entity)
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var detectedOrgs: [String] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, tokenRange in
            if tag == .organizationName {
                let orgName = String(text[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if orgName.count > 2 && !detectedOrgs.contains(orgName) {
                    detectedOrgs.append(orgName)
                }
            }
            return true
        }

        if let primaryOrg = detectedOrgs.first {
            result.counterparty = ConfidentField(value: primaryOrg, confidence: 0.75, sourceText: primaryOrg)
        }

        // 2. Monetary amounts ($XX.XX or ₹XX.XX or €XX.XX)
        let amountPattern = #"(?:[\$\€\£\₹]|USD|EUR|INR|GBP)\s?([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: nsRange),
               let matchRange = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[matchRange]).replacingOccurrences(of: ",", with: "")
                if let decimal = Decimal(string: amountStr) {
                    result.monetaryAmount = ConfidentField(value: decimal, confidence: 0.80, sourceText: String(text[Range(match.range, in: text)!]))
                }
            }
        }

        // 3. Reference numbers (Policy #, Order #, Invoice #)
        let refPattern = #"(?:order|policy|invoice|account|ref|id)[\s#:]+([A-Z0-9\-]{5,24})"#
        if let regex = try? NSRegularExpression(pattern: refPattern, options: .caseInsensitive) {
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: nsRange),
               let matchRange = Range(match.range(at: 1), in: text) {
                let refStr = String(text[matchRange])
                result.referenceNumber = ConfidentField(value: refStr, confidence: 0.85, sourceText: refStr)
            }
        }

        // 4. Date extraction using NSDataDetector
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
            for match in matches {
                if let date = match.date, date > Date.now.addingTimeInterval(-86400 * 365) {
                    result.keyDates["detected_date"] = ConfidentField(value: date, confidence: 0.70)
                    break
                }
            }
        }

        result.summary = String(text.prefix(160)).cleanedInput
        return result
    }

    // MARK: - Case Planning

    func planCase(intent: String, extractedInfo: AIExtractionResult?) async throws -> AICasePlan {
        let classification = try await classify(text: intent)
        let extracted = try await extract(text: intent, expectedType: classification.documentType)

        var actions: [AIPlannedAction] = []
        var requirements: [AIPlannedRequirement] = []
        var title = intent.prefix(60).trimmingCharacters(in: .whitespacesAndNewlines)
        var deadline: Date? = extracted.keyDates.values.first?.value

        switch classification.caseType {
        case .purchaseReturn:
            if title.isEmpty { title = "Return item to \(extracted.counterparty?.value ?? "Seller")" }
            if deadline == nil {
                deadline = Calendar.current.date(byAdding: .day, value: 14, to: .now)
            }
            actions = [
                AIPlannedAction(title: "Check return eligibility window", actionType: .read, orderIndex: 0),
                AIPlannedAction(title: "Repack item with original tags & packaging", actionType: .custom, orderIndex: 1),
                AIPlannedAction(title: "Generate return shipping label or drop-off QR code", actionType: .openURL, orderIndex: 2),
                AIPlannedAction(title: "Drop off package at courier / drop point", actionType: .custom, orderIndex: 3),
                AIPlannedAction(title: "Verify refund credited to payment account", actionType: .pay, orderIndex: 4)
            ]
            requirements = [
                AIPlannedRequirement(title: "Original item with undamaged packaging", requirementType: .document),
                AIPlannedRequirement(title: "Invoice or Order confirmation", requirementType: .document)
            ]

        case .insuranceWarranty:
            if title.isEmpty { title = "Policy / Warranty Claim: \(extracted.counterparty?.value ?? "Provider")" }
            if deadline == nil {
                deadline = Calendar.current.date(byAdding: .day, value: 30, to: .now)
            }
            actions = [
                AIPlannedAction(title: "Review coverage terms & deductible amount", actionType: .read, orderIndex: 0),
                AIPlannedAction(title: "Gather supporting receipts & incident proof", actionType: .upload, orderIndex: 1),
                AIPlannedAction(title: "Submit claim form online or call support", actionType: .call, orderIndex: 2),
                AIPlannedAction(title: "Track claim settlement reference number", actionType: .custom, orderIndex: 3)
            ]
            requirements = [
                AIPlannedRequirement(title: "Active policy or warranty number", requirementType: .personalInformation),
                AIPlannedRequirement(title: "Original purchase invoice", requirementType: .document)
            ]

        case .documentRenewal:
            if title.isEmpty { title = "Renew Document" }
            if deadline == nil {
                deadline = Calendar.current.date(byAdding: .month, value: 1, to: .now)
            }
            actions = [
                AIPlannedAction(title: "Verify document expiry date & renewal criteria", actionType: .read, orderIndex: 0),
                AIPlannedAction(title: "Take new passport/identity compliant photo", actionType: .upload, orderIndex: 1),
                AIPlannedAction(title: "Complete official online renewal application", actionType: .fillForm, orderIndex: 2),
                AIPlannedAction(title: "Pay renewal fee & book biometric appointment", actionType: .pay, orderIndex: 3)
            ]
            requirements = [
                AIPlannedRequirement(title: "Current official document", requirementType: .document),
                AIPlannedRequirement(title: "Proof of address / identity verification", requirementType: .document)
            ]

        case .subscriptionBill:
            if title.isEmpty { title = "Manage \(extracted.counterparty?.value ?? "Subscription / Bill")" }
            if deadline == nil {
                deadline = Calendar.current.date(byAdding: .day, value: 7, to: .now)
            }
            actions = [
                AIPlannedAction(title: "Review charges and billing cycle", actionType: .read, orderIndex: 0),
                AIPlannedAction(title: "Update payment method or cancel renewal", actionType: .pay, orderIndex: 1),
                AIPlannedAction(title: "Confirm cancellation or payment receipt", actionType: .confirm, orderIndex: 2)
            ]
            requirements = [
                AIPlannedRequirement(title: "Account login / Customer ID", requirementType: .personalInformation)
            ]

        case .genericLifeAdmin:
            if title.isEmpty { title = "Life Admin Case" }
            actions = [
                AIPlannedAction(title: "Review matter details and requirements", actionType: .read, orderIndex: 0),
                AIPlannedAction(title: "Execute primary action step", actionType: .custom, orderIndex: 1),
                AIPlannedAction(title: "Confirm resolution and archive record", actionType: .confirm, orderIndex: 2)
            ]
            requirements = [
                AIPlannedRequirement(title: "Relevant documents / details", requirementType: .document)
            ]
        }

        return AICasePlan(
            title: title,
            descriptionText: intent,
            caseType: classification.caseType,
            suggestedPriority: .normal,
            suggestedDeadline: deadline,
            actions: actions,
            requirements: requirements,
            extractedFields: extracted,
            confidence: classification.confidence
        )
    }
}
