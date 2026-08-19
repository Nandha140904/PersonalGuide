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
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("PersonalGuide/Documents", isDirectory: true)
    }

    private var thumbnailsDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("PersonalGuide/Thumbnails", isDirectory: true)
    }

    private func createStorageDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Document Ingestion & Storage

    /// Save an image document, compute its hash, generate a thumbnail, and run OCR.
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
        let fileExtension = "jpg"
        let storageFileName = "\(documentId.uuidString).\(fileExtension)"
        let fileURL = documentsDirectory.appendingPathComponent(storageFileName)

        // 1. Write file to local disk
        try imageData.write(to: fileURL, options: .atomic)

        // 2. Compute SHA-256 checksum
        let checksum = SHA256.hash(data: imageData).compactMap { String(format: "%02x", $0) }.joined()

        // 3. Generate and save thumbnail
        let thumbnailData = generateThumbnail(from: image)
        let thumbnailFileName = "\(documentId.uuidString)_thumb.jpg"
        let thumbURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        if let thumbnailData {
            try? thumbnailData.write(to: thumbURL, options: .atomic)
        }

        // 4. Run Apple Vision OCR on device
        let ocrResult = try? await ocrService.recognizeText(from: image)
        let ocrText = ocrResult?.fullText ?? ""

        // 5. Create PGDocument entity
        let document = PGDocument(
            fileName: fileName.isEmpty ? "Scanned Document" : fileName,
            fileType: fileExtension,
            fileSize: Int64(imageData.count),
            localPath: fileURL.path,
            documentType: documentType,
            ocrText: ocrText
        )
        document.id = documentId
        document.checksum = checksum
        document.thumbnailData = thumbnailData

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
        guard let localPath = document.localPath else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: localPath))
    }

    /// Delete a document record and its corresponding files on disk.
    func deleteDocument(_ document: PGDocument, in context: ModelContext) {
        if let localPath = document.localPath {
            try? fileManager.removeItem(atPath: localPath)
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
