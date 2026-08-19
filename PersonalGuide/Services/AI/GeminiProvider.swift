// MARK: - GeminiProvider.swift
// PersonalGuide
//
// Cloud AI provider using Google's Gemini API for structured life-admin planning and extraction.

import Foundation

final class GeminiProvider: AIProvider, @unchecked Sendable {

    let providerName = "Google Gemini"
    private let apiKey: String
    private let session: URLSession

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(apiKey: String = "", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Classification

    func classify(text: String) async throws -> AIClassificationResult {
        let prompt = """
        Analyze this life administration text and classify it into one of these case types:
        - PURCHASE_RETURN (returns, refunds, defective items, deliveries)
        - SUBSCRIPTION_BILL (utility bills, streaming services, phone bills, recurring subscriptions)
        - DOCUMENT_RENEWAL (passports, driver licenses, visas, identification renewals)
        - INSURANCE_WARRANTY (insurance policies, warranty claims, healthcare claims, car claims)
        - GENERIC_LIFE_ADMIN (all other life admin)

        Return JSON matching this schema:
        {
          "caseType": "PURCHASE_RETURN" | "SUBSCRIPTION_BILL" | "DOCUMENT_RENEWAL" | "INSURANCE_WARRANTY" | "GENERIC_LIFE_ADMIN",
          "documentType": "RECEIPT" | "INVOICE" | "BILL" | "POLICY" | "IDENTIFICATION" | "CONTRACT" | "OTHER",
          "confidence": 0.0 to 1.0,
          "rationale": "short explanation"
        }

        Text: "\(text)"
        """

        let json = try await generateStructuredContent(prompt: prompt)
        let caseTypeStr = json["caseType"] as? String ?? "GENERIC_LIFE_ADMIN"
        let docTypeStr = json["documentType"] as? String ?? "OTHER"
        let confidence = json["confidence"] as? Double ?? 0.85
        let rationale = json["rationale"] as? String ?? ""

        return AIClassificationResult(
            caseType: CaseType(rawValue: caseTypeStr) ?? .genericLifeAdmin,
            documentType: DocumentType(rawValue: docTypeStr) ?? .other,
            confidence: confidence,
            rationale: rationale
        )
    }

    // MARK: - Extraction

    func extract(text: String, expectedType: DocumentType?) async throws -> AIExtractionResult {
        let prompt = """
        Extract all factual life-administration entities from the following text with confidence ratings (0.0 to 1.0).

        Return JSON matching this schema:
        {
          "counterparty": {"value": "Merchant/Insurer name", "confidence": 0.95},
          "referenceNumber": {"value": "Policy or Order or Invoice #", "confidence": 0.9},
          "monetaryAmount": {"value": 129.99, "currency": "USD", "confidence": 0.9},
          "deadlineDate": {"value": "YYYY-MM-DD", "confidence": 0.85},
          "summary": "Brief 1-sentence summary"
        }

        Text: "\(text)"
        """

        let json = try await generateStructuredContent(prompt: prompt)
        var result = AIExtractionResult()

        if let counterpartyObj = json["counterparty"] as? [String: Any],
           let val = counterpartyObj["value"] as? String {
            let conf = counterpartyObj["confidence"] as? Double ?? 0.8
            result.counterparty = ConfidentField(value: val, confidence: conf)
        }

        if let refObj = json["referenceNumber"] as? [String: Any],
           let val = refObj["value"] as? String {
            let conf = refObj["confidence"] as? Double ?? 0.8
            result.referenceNumber = ConfidentField(value: val, confidence: conf)
        }

        if let amountObj = json["monetaryAmount"] as? [String: Any],
           let val = amountObj["value"] as? Double {
            let conf = amountObj["confidence"] as? Double ?? 0.8
            result.monetaryAmount = ConfidentField(value: Decimal(val), confidence: conf)
            if let cur = amountObj["currency"] as? String {
                result.currencyCode = cur
            }
        }

        if let dateObj = json["deadlineDate"] as? [String: Any],
           let dateStr = dateObj["value"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateStr) {
                let conf = dateObj["confidence"] as? Double ?? 0.8
                result.keyDates["deadline"] = ConfidentField(value: date, confidence: conf)
            }
        }

        result.summary = json["summary"] as? String ?? ""
        return result
    }

    // MARK: - Case Planning

    func planCase(intent: String, extractedInfo: AIExtractionResult?) async throws -> AICasePlan {
        let prompt = """
        You are Personal Guide, an expert life-administration engine. Turn the user's intent into a structured case plan with concrete, ordered steps and physical/documentary requirements.

        User Intent: "\(intent)"

        Return JSON matching this schema:
        {
          "title": "Clear concise case title",
          "description": "Short explanation",
          "caseType": "PURCHASE_RETURN" | "SUBSCRIPTION_BILL" | "DOCUMENT_RENEWAL" | "INSURANCE_WARRANTY" | "GENERIC_LIFE_ADMIN",
          "priority": "LOW" | "NORMAL" | "HIGH" | "URGENT" | "CRITICAL",
          "deadlineDate": "YYYY-MM-DD" or null,
          "confidence": 0.0 to 1.0,
          "actions": [
            {
              "title": "Action step title",
              "description": "Details",
              "actionType": "READ" | "UPLOAD" | "CALL" | "PAY" | "VISIT" | "DOWNLOAD" | "FORM" | "CUSTOM",
              "orderIndex": 0,
              "isRequired": true,
              "confidence": 0.9
            }
          ],
          "requirements": [
            {
              "title": "Requirement title (e.g. Receipt, Box, ID)",
              "description": "Why needed",
              "requirementType": "DOCUMENT" | "CREDENTIAL" | "PHYSICAL_ITEM" | "PAYMENT" | "OTHER",
              "isRequired": true,
              "confidence": 0.9
            }
          ]
        }
        """

        let json = try await generateStructuredContent(prompt: prompt)

        let title = json["title"] as? String ?? intent.prefix(50).description
        let desc = json["description"] as? String ?? intent
        let caseTypeStr = json["caseType"] as? String ?? "GENERIC_LIFE_ADMIN"
        let priorityStr = json["priority"] as? String ?? "NORMAL"
        let confidence = json["confidence"] as? Double ?? 0.85

        var deadline: Date?
        if let dateStr = json["deadlineDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            deadline = formatter.date(from: dateStr)
        }

        var actions: [AIPlannedAction] = []
        if let actionsJson = json["actions"] as? [[String: Any]] {
            for (idx, item) in actionsJson.enumerated() {
                let actionTitle = item["title"] as? String ?? "Step \(idx + 1)"
                let actionDesc = item["description"] as? String ?? ""
                let typeStr = item["actionType"] as? String ?? "CUSTOM"
                let isReq = item["isRequired"] as? Bool ?? true
                let conf = item["confidence"] as? Double ?? 0.9
                actions.append(AIPlannedAction(
                    title: actionTitle,
                    descriptionText: actionDesc,
                    actionType: ActionType(rawValue: typeStr) ?? .custom,
                    orderIndex: idx,
                    isRequired: isReq,
                    confidence: conf
                ))
            }
        }

        var requirements: [AIPlannedRequirement] = []
        if let reqsJson = json["requirements"] as? [[String: Any]] {
            for item in reqsJson {
                let reqTitle = item["title"] as? String ?? "Requirement"
                let reqDesc = item["description"] as? String ?? ""
                let typeStr = item["requirementType"] as? String ?? "DOCUMENT"
                let isReq = item["isRequired"] as? Bool ?? true
                let conf = item["confidence"] as? Double ?? 0.9
                requirements.append(AIPlannedRequirement(
                    title: reqTitle,
                    descriptionText: reqDesc,
                    requirementType: RequirementType(rawValue: typeStr) ?? .document,
                    isRequired: isReq,
                    confidence: conf
                ))
            }
        }

        return AICasePlan(
            title: title,
            descriptionText: desc,
            caseType: CaseType(rawValue: caseTypeStr) ?? .genericLifeAdmin,
            suggestedPriority: CasePriority(rawValue: priorityStr) ?? .normal,
            suggestedDeadline: deadline,
            actions: actions,
            requirements: requirements,
            confidence: confidence
        )
    }

    // MARK: - Gemini API Network Transport

    private func generateStructuredContent(prompt: String) async throws -> [String: Any] {
        guard isConfigured else {
            throw AIError.missingAPIKey(provider: providerName)
        }

        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw AIError.networkError("Invalid Gemini endpoint URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.2
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AIError.apiError("Gemini API error (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 500))")
        }

        guard let rootJson = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = rootJson["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIError.parsingFailed
        }

        guard let textData = text.data(using: .utf8),
              let parsedJSON = try JSONSerialization.jsonObject(with: textData) as? [String: Any] else {
            throw AIError.parsingFailed
        }

        return parsedJSON
    }
}

enum AIError: LocalizedError {
    case missingAPIKey(provider: String)
    case networkError(String)
    case apiError(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "No API key configured for \(provider)."
        case .networkError(let message):
            return "Network connection failed: \(message)"
        case .apiError(let message):
            return "AI service error: \(message)"
        case .parsingFailed:
            return "Failed to parse structured response from AI."
        }
    }
}
