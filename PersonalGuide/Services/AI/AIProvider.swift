// MARK: - AIProvider.swift
// PersonalGuide
//
// Protocol defining the pluggable AI backend interface.
// Allows swapping between Google Gemini, OpenAI, and Apple On-Device models seamlessly.

import Foundation

public protocol AIProvider: Sendable {
    var providerName: String { get }
    var isConfigured: Bool { get }

    /// Classify raw text / OCR into a case type and document category.
    func classify(text: String) async throws -> AIClassificationResult

    /// Extract structured entities (counterparty, dates, amounts, reference numbers) from text.
    func extract(text: String, expectedType: DocumentType?) async throws -> AIExtractionResult

    /// Generate an actionable life-administration plan from an intent or document.
    func planCase(intent: String, extractedInfo: AIExtractionResult?) async throws -> AICasePlan
}

public enum AIProviderType: String, CaseIterable, Identifiable, Sendable {
    case onDevice = "on_device"
    case gemini = "gemini"
    case openAI = "openai"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .onDevice: return "On-Device (Apple Vision & NL)"
        case .gemini:   return "Google Gemini"
        case .openAI:   return "OpenAI"
        }
    }

    public var isCloud: Bool {
        self != .onDevice
    }
}
