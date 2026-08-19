// MARK: - DataExportService.swift
// PersonalGuide
//
// Generates structured, privacy-preserving JSON export archives of all user data.

import Foundation
import SwiftData

@MainActor
final class DataExportService {

    struct ExportBundle: Codable {
        let exportDate: Date
        let appVersion: String
        let cases: [ExportCase]
        let assets: [ExportAsset]
        let documents: [ExportDocument]
    }

    struct ExportCase: Codable {
        let id: UUID
        let title: String
        let description: String
        let caseType: String
        let status: String
        let priority: String
        let deadline: Date?
        let createdAt: Date
        let actions: [ExportAction]
        let requirements: [ExportRequirement]
    }

    struct ExportAction: Codable {
        let id: UUID
        let title: String
        let description: String
        let actionType: String
        let status: String
        let isRequired: Bool
    }

    struct ExportRequirement: Codable {
        let id: UUID
        let title: String
        let requirementType: String
        let status: String
        let isRequired: Bool
    }

    struct ExportAsset: Codable {
        let id: UUID
        let name: String
        let assetType: String
        let manufacturer: String?
        let modelNumber: String?
        let serialNumber: String?
        let purchaseDate: Date?
        let warrantyEndDate: Date?
    }

    struct ExportDocument: Codable {
        let id: UUID
        let fileName: String
        let mimeType: String
        let documentType: String
        let extractedText: String?
        let createdAt: Date
    }

    // MARK: - Export Execution

    static func generateExportJSON(
        cases: [PGCase],
        assets: [Asset],
        documents: [PGDocument]
    ) throws -> URL {
        let exportCases = cases.map { c in
            ExportCase(
                id: c.id,
                title: c.title,
                description: c.descriptionText,
                caseType: c.caseTypeRaw,
                status: c.statusRaw,
                priority: c.priorityRaw,
                deadline: c.deadline,
                createdAt: c.createdAt,
                actions: c.actions.map { a in
                    ExportAction(
                        id: a.id,
                        title: a.title,
                        description: a.descriptionText,
                        actionType: a.actionTypeRaw,
                        status: a.statusRaw,
                        isRequired: a.isRequired
                    )
                },
                requirements: c.requirements.map { r in
                    ExportRequirement(
                        id: r.id,
                        title: r.title,
                        requirementType: r.requirementTypeRaw,
                        status: r.statusRaw,
                        isRequired: r.isRequired
                    )
                }
            )
        }

        let exportAssets = assets.map { a in
            ExportAsset(
                id: a.id,
                name: a.name,
                assetType: a.assetTypeRaw,
                manufacturer: a.manufacturer,
                modelNumber: a.modelNumber,
                serialNumber: a.serialNumber,
                purchaseDate: a.purchaseDate,
                warrantyEndDate: a.warrantyEndDate
            )
        }

        let exportDocs = documents.map { d in
            ExportDocument(
                id: d.id,
                fileName: d.fileName,
                mimeType: d.mimeType,
                documentType: d.documentTypeRaw,
                extractedText: d.extractedText,
                createdAt: d.createdAt
            )
        }

        let bundle = ExportBundle(
            exportDate: .now,
            appVersion: "1.0.0",
            cases: exportCases,
            assets: exportAssets,
            documents: exportDocs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(bundle)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("PersonalGuide_Export_\(Date.now.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json")

        try data.write(to: fileURL)
        return fileURL
    }
}
