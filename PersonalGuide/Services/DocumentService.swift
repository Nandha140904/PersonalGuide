// MARK: - DocumentService.swift
// PersonalGuide
//
// Local file storage, thumbnail generation, checksum verification,
// and document management for all user administration records.

import Foundation
import UIKit
import SwiftData
import CryptoKit

@Observable
final class DocumentService: @unchecked Sendable {

    private let fileManager = FileManager.default
    private let ocrService = VisionOCRService.shared

    init() {
        createStorageDirectoriesIfNeeded()
    }

    // MARK: - Storage Paths

    private var documentsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("PersonalGuide/Documents", isDirectory: true)
    }

    private var thumbnailsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("PersonalGuide/Thumbnails", isDirectory: true)
    }

    private func createStorageDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Document Ingestion & Storage

    /// Save an image document, compute its hash, generate a thumbnail, and run OCR.
    @MainActor
    func ingestDocument(
        image: UIImage,
        fileName: String,
        documentType: DocumentType = .other,
        in context: ModelContext
    ) async throws -> PGDocument {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw DocumentError.imageConversionFailed
        }

        let documentId = UUID()
        let relativeStoragePath = "PersonalGuide/Documents/\(documentId.uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent("\(documentId.uuidString).jpg")

        // 1. Write file to local disk
        try imageData.write(to: fileURL, options: .atomic)

        // 2. Compute SHA-256 checksum
        let checksum = SHA256.hash(data: imageData).compactMap { String(format: "%02x", $0) }.joined()

        // 3. Generate and save thumbnail
        let thumbnailData = generateThumbnail(from: image)
        let thumbURL = thumbnailsDirectory.appendingPathComponent("\(documentId.uuidString)_thumb.jpg")
        if let thumbnailData {
            try? thumbnailData.write(to: thumbURL, options: .atomic)
        }

        // 4. Run Apple Vision OCR on device
        let ocrResult = try? await ocrService.recognizeText(from: image)
        let ocrText = ocrResult?.fullText ?? ""

        // 5. Create PGDocument entity
        let document = PGDocument(
            fileName: fileName.isEmpty ? "Scanned Document" : fileName,
            mimeType: "image/jpeg",
            storagePath: relativeStoragePath,
            documentType: documentType,
            classificationConfidence: ocrResult?.confidence ?? 0.0
        )
        document.id = documentId
        document.contentHash = checksum
        document.extractedText = ocrText

        context.insert(document)
        try? context.save()

        return document
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from image: UIImage, targetSize: CGSize = CGSize(width: 160, height: 160)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            let aspectWidth = targetSize.width / image.size.width
            let aspectHeight = targetSize.height / image.size.height
            let aspectRatio = max(aspectWidth, aspectHeight)

            let scaledWidth = image.size.width * aspectRatio
            let scaledHeight = image.size.height * aspectRatio
            let originX = (targetSize.width - scaledWidth) / 2.0
            let originY = (targetSize.height - scaledHeight) / 2.0

            image.draw(in: CGRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Document Retrieval & Deletion

    /// Load document image data from local sandbox.
    func loadDocumentData(for document: PGDocument) -> Data? {
        guard let url = document.fileURL else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Delete a document record and its corresponding files on disk.
    @MainActor
    func deleteDocument(_ document: PGDocument, in context: ModelContext) {
        if let url = document.fileURL {
            try? fileManager.removeItem(at: url)
        }
        let thumbURL = thumbnailsDirectory.appendingPathComponent("\(document.id.uuidString)_thumb.jpg")
        try? fileManager.removeItem(at: thumbURL)

        context.delete(document)
        try? context.save()
    }
}

enum DocumentError: LocalizedError {
    case imageConversionFailed
    case fileNotFound
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Could not convert the image to standard document format."
        case .fileNotFound:
            return "The requested document file could not be located on disk."
        case .writeFailed:
            return "Failed to save the document file to local storage."
        }
    }
}
