// MARK: - OpenAIProvider.swift
// PersonalGuide
//
// Cloud AI provider using OpenAI's chat completions API (GPT-4o-mini).

import Foundation

final class OpenAIProvider: AIProvider, @unchecked Sendable {

    let providerName = "OpenAI"
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
        Classify this life administration text into one of: PURCHASE_RETURN, SUBSCRIPTION_BILL, DOCUMENT_RENEWAL, INSURANCE_WARRANTY, GENERIC_LIFE_ADMIN.
        Return JSON matching: {"caseType": "...", "documentType": "...", "confidence": 0.9, "rationale": "..."}
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
        Extract all factual life-administration entities from the text with confidence (0.0 to 1.0).
        Return JSON matching:
        {
          "counterparty": {"value": "...", "confidence": 0.9},
          "referenceNumber": {"value": "...", "confidence": 0.9},
          "monetaryAmount": {"value": 100.0, "currency": "USD", "confidence": 0.9},
          "deadlineDate": {"value": "YYYY-MM-DD", "confidence": 0.85},
          "summary": "..."
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
        You are Personal Guide, an expert life-administration engine. Turn this intent into a structured case plan with actions and requirements.
        Intent: "\(intent)"
        Return JSON:
        {
          "title": "...",
          "description": "...",
          "caseType": "PURCHASE_RETURN" | "SUBSCRIPTION_BILL" | "DOCUMENT_RENEWAL" | "INSURANCE_WARRANTY" | "GENERIC_LIFE_ADMIN",
          "priority": "LOW" | "NORMAL" | "HIGH" | "URGENT" | "CRITICAL",
          "deadlineDate": "YYYY-MM-DD" or null,
          "confidence": 0.9,
          "actions": [{"title": "...", "description": "...", "actionType": "...", "orderIndex": 0, "isRequired": true, "confidence": 0.9}],
          "requirements": [{"title": "...", "description": "...", "requirementType": "...", "isRequired": true, "confidence": 0.9}]
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

    // MARK: - OpenAI Network Transport

    private func generateStructuredContent(prompt: String) async throws -> [String: Any] {
        guard isConfigured else {
            throw AIError.missingAPIKey(provider: providerName)
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIError.networkError("Invalid OpenAI endpoint URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are Personal Guide, an expert life-administration engine. Always respond in valid JSON matching the requested schema."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.2
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AIError.apiError("OpenAI API error (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 500))")
        }

        guard let rootJson = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = rootJson["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parsingFailed
        }

        guard let textData = content.data(using: .utf8),
              let parsedJSON = try JSONSerialization.jsonObject(with: textData) as? [String: Any] else {
            throw AIError.parsingFailed
        }

        return parsedJSON
    }
}
