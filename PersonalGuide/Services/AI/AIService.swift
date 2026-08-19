// MARK: - AIService.swift
// PersonalGuide
//
// Central AI orchestrator. Manages provider selection (Gemini, OpenAI, On-Device),
// automatic offline fallback, and document intelligence pipelines.

import Foundation
import UIKit
import SwiftData

@Observable
final class AIService: @unchecked Sendable {

    var activeProviderType: AIProviderType = .onDevice
    var geminiApiKey: String = ""
    var openAIApiKey: String = ""

    private let onDeviceProvider = OnDeviceProvider()
    private var geminiProvider: GeminiProvider { GeminiProvider(apiKey: geminiApiKey) }
    private var openAIProvider: OpenAIProvider { OpenAIProvider(apiKey: openAIApiKey) }

    init() {}

    // MARK: - Active Provider Resolution

    var currentProvider: any AIProvider {
        switch activeProviderType {
        case .gemini:
            return geminiProvider.isConfigured ? geminiProvider : onDeviceProvider
        case .openAI:
            return openAIProvider.isConfigured ? openAIProvider : onDeviceProvider
        case .onDevice:
            return onDeviceProvider
        }
    }

    // MARK: - Plan Case from Natural Language

    /// Plan a case from user's conversational description with automatic offline fallback.
    func planCase(from naturalLanguage: String) async -> CaseDraft {
        do {
            let plan = try await currentProvider.planCase(intent: naturalLanguage, extractedInfo: nil)
            return makeDraft(from: plan)
        } catch {
            // Automatic fallback to on-device provider if cloud provider fails
            let plan = (try? await onDeviceProvider.planCase(intent: naturalLanguage, extractedInfo: nil))
            if let plan {
                return makeDraft(from: plan)
            }
            return CaseDraft.fromNaturalLanguage(naturalLanguage)
        }
    }

    // MARK: - Process Scanned Document Pipeline

    /// Full document processing pipeline: OCR -> Classify -> Extract -> Plan -> Draft.
    func processDocument(
        ocrText: String,
        document: PGDocument?
    ) async -> CaseDraft {
        do {
            let classification = try await currentProvider.classify(text: ocrText)
            let extracted = try await currentProvider.extract(text: ocrText, expectedType: classification.documentType)
            let plan = try await currentProvider.planCase(intent: ocrText, extractedInfo: extracted)

            var draft = makeDraft(from: plan)
            draft.source = .documentScan
            draft.documentType = classification.documentType
            return draft
        } catch {
            let fallbackPlan = try? await onDeviceProvider.planCase(intent: ocrText, extractedInfo: nil)
            if let fallbackPlan {
                var draft = makeDraft(from: fallbackPlan)
                draft.source = .documentScan
                return draft
            }
            return CaseDraft(
                title: "Scanned Document",
                descriptionText: String(ocrText.prefix(200)),
                caseType: .genericLifeAdmin,
                source: .documentScan
            )
        }
    }

    // MARK: - Helper

    private func makeDraft(from plan: AICasePlan) -> CaseDraft {
        var draft = CaseDraft(
            title: plan.title,
            descriptionText: plan.descriptionText,
            caseType: plan.caseType,
            source: .naturalLanguage,
            deadline: plan.suggestedDeadline,
            priority: plan.suggestedPriority,
            confidence: plan.confidence
        )

        draft.actions = plan.actions.map { action in
            CaseActionDraft(
                title: action.title,
                descriptionText: action.descriptionText,
                actionType: action.actionType,
                isRequired: action.isRequired,
                externalURL: action.externalURL,
                source: "ai_planner"
            )
        }

        draft.requirements = plan.requirements.map { req in
            CaseRequirementDraft(
                title: req.title,
                descriptionText: req.descriptionText,
                requirementType: req.requirementType,
                isRequired: req.isRequired,
                confidence: req.confidence,
                source: "ai_planner"
            )
        }

        return draft
    }
}
