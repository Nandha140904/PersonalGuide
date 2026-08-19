// MARK: - SearchService.swift
// PersonalGuide
//
// Full-text, relationship-aware search engine across all life-administration entities:
// Cases, Documents (including OCR text), Assets, and Actions.

import Foundation
import SwiftData

@MainActor
@Observable
final class SearchService {

    init() {}

    // MARK: - Search Result Models

    enum SearchResultItem: Identifiable {
        case caseItem(PGCase)
        case documentItem(PGDocument)
        case assetItem(Asset)
        case actionItem(CaseAction, PGCase)

        var id: UUID {
            switch self {
            case .caseItem(let c): return c.id
            case .documentItem(let d): return d.id
            case .assetItem(let a): return a.id
            case .actionItem(let act, _): return act.id
            }
        }

        var title: String {
            switch self {
            case .caseItem(let c): return c.title
            case .documentItem(let d): return d.fileName
            case .assetItem(let a): return a.name
            case .actionItem(let act, _): return act.title
            }
        }

        var subtitle: String {
            switch self {
            case .caseItem(let c):
                return c.caseType.displayName + " • " + c.status.displayName
            case .documentItem(let d):
                return (d.issuer ?? d.documentType.displayName) + (d.extractedText != nil ? " • Text indexed" : "")
            case .assetItem(let a):
                return a.assetType.displayName + (a.serialNumber != nil ? " • S/N: \(a.serialNumber!)" : "")
            case .actionItem(_, let parent):
                return "Action in \(parent.title)"
            }
        }

        var iconName: String {
            switch self {
            case .caseItem(let c): return c.caseType.iconName
            case .documentItem(let d): return d.documentType.iconName
            case .assetItem(let a): return a.assetType.iconName
            case .actionItem(let act, _): return act.actionType.iconName
            }
        }
    }

    struct GroupedSearchResults {
        var cases: [PGCase] = []
        var documents: [PGDocument] = []
        var assets: [Asset] = []
        var actions: [(action: CaseAction, parentCase: PGCase)] = []

        var isEmpty: Bool {
            cases.isEmpty && documents.isEmpty && assets.isEmpty && actions.isEmpty
        }

        var totalCount: Int {
            cases.count + documents.count + assets.count + actions.count
        }
    }

    // MARK: - Live Search Query

    func search(
        query: String,
        allCases: [PGCase],
        allDocuments: [PGDocument],
        allAssets: [Asset]
    ) -> GroupedSearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return GroupedSearchResults() }

        var results = GroupedSearchResults()

        // 1. Search Cases
        results.cases = allCases.filter { pgCase in
            pgCase.title.lowercased().contains(trimmed) ||
            pgCase.descriptionText.lowercased().contains(trimmed) ||
            (pgCase.category?.lowercased().contains(trimmed) ?? false) ||
            (pgCase.externalReference?.lowercased().contains(trimmed) ?? false) ||
            pgCase.caseType.displayName.lowercased().contains(trimmed)
        }

        // 2. Search Documents (including OCR extracted text)
        results.documents = allDocuments.filter { doc in
            doc.fileName.lowercased().contains(trimmed) ||
            (doc.issuer?.lowercased().contains(trimmed) ?? false) ||
            doc.documentType.displayName.lowercased().contains(trimmed) ||
            (doc.extractedText?.lowercased().contains(trimmed) ?? false)
        }

        // 3. Search Assets
        results.assets = allAssets.filter { asset in
            asset.name.lowercased().contains(trimmed) ||
            (asset.manufacturer?.lowercased().contains(trimmed) ?? false) ||
            (asset.modelNumber?.lowercased().contains(trimmed) ?? false) ||
            (asset.serialNumber?.lowercased().contains(trimmed) ?? false) ||
            asset.assetType.displayName.lowercased().contains(trimmed)
        }

        // 4. Search Actions across all cases
        for pgCase in allCases {
            for action in pgCase.actions {
                if action.title.lowercased().contains(trimmed) ||
                   action.descriptionText.lowercased().contains(trimmed) {
                    results.actions.append((action, pgCase))
                }
            }
        }

        return results
    }
}
