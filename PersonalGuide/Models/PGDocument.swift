// MARK: - PGDocument.swift
// PersonalGuide
//
// A document uploaded by the user — receipt, policy, bill, ID, etc.
// Documents are evidence and inputs, not the product itself.
// The processing pipeline: Upload → Validate → OCR → Classify → Extract → Confirm → Save → Link

import Foundation
import SwiftData

@Model
final class PGDocument {

    var id: UUID
    var fileName: String
    var mimeType: String

    /// Relative path within the app's documents directory.
    var storagePath: String

    /// SHA-256 hash for deduplication and integrity.
    var contentHash: String?

    // MARK: - Classification

    var documentTypeRaw: String

    /// Who issued this document (e.g., "HDFC Ergo", "Amazon", "Government of India").
    var issuer: String?
    var issueDate: Date?
    var expiryDate: Date?

    // MARK: - Extraction

    /// Raw OCR text extracted from the document.
    var extractedText: String?

    /// Structured data extracted by AI (JSON-encoded).
    /// Contains key-value pairs like policy_number, amount, etc.
    var extractedDataJSON: String?

    /// How confident the classifier was about the document type (0.0–1.0).
    var classificationConfidence: Double

    // MARK: - Dates

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var parentCase: PGCase?

    // MARK: - Init

    init(
        fileName: String,
        mimeType: String,
        storagePath: String,
        documentType: DocumentType = .other,
        classificationConfidence: Double = 0.0
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.mimeType = mimeType
        self.storagePath = storagePath
        self.documentTypeRaw = documentType.rawValue
        self.classificationConfidence = classificationConfidence
        self.createdAt = .now
        self.updatedAt = .now
    }

    // MARK: - Computed

    var documentType: DocumentType {
        get { DocumentType(rawValue: documentTypeRaw) ?? .other }
        set {
            documentTypeRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    /// Whether the document has been processed (OCR + extraction completed).
    var isProcessed: Bool {
        extractedText != nil
    }

    /// Whether the classification confidence is high enough to trust without confirmation.
    var isHighConfidence: Bool {
        classificationConfidence >= 0.85
    }

    /// Structured extracted data as a dictionary.
    var extractedData: [String: String] {
        get {
            guard let json = extractedDataJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8)
            else { return }
            extractedDataJSON = json
            updatedAt = .now
        }
    }

    /// Full URL to the document file on disk.
    var fileURL: URL? {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDir?.appendingPathComponent(storagePath)
    }
}
