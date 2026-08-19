// MARK: - VisionOCRService.swift
// PersonalGuide
//
// On-device text recognition using Apple's Vision framework (VNRecognizeTextRequest).
// Fast, private, and works 100% offline with zero cloud dependency.

import Foundation
import Vision
import UIKit

struct OCRResult: Sendable {
    let fullText: String
    let recognizedLines: [OCRLine]
    let confidence: Double

    init(fullText: String, recognizedLines: [OCRLine], confidence: Double) {
        self.fullText = fullText
        self.recognizedLines = recognizedLines
        self.confidence = confidence
    }
}

struct OCRLine: Sendable, Identifiable {
    var id = UUID()
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

actor VisionOCRService {

    static let shared = VisionOCRService()

    init() {}

    /// Recognize text from a UIImage using Apple Vision framework on-device.
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(fullText: "", recognizedLines: [], confidence: 0.0))
                    return
                }

                var fullTextParts: [String] = []
                var lines: [OCRLine] = []
                var totalConfidence: Float = 0.0

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }

                    let lineText = topCandidate.string
                    fullTextParts.append(lineText)
                    lines.append(OCRLine(
                        text: lineText,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    ))
                    totalConfidence += topCandidate.confidence
                }

                let averageConfidence = lines.isEmpty ? 0.0 : Double(totalConfidence) / Double(lines.count)
                let fullText = fullTextParts.joined(separator: "\n")

                continuation.resume(returning: OCRResult(
                    fullText: fullText,
                    recognizedLines: lines,
                    confidence: averageConfidence
                ))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "en-GB", "en-IN"]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image data is invalid or could not be processed."
        case .processingFailed:
            return "Optical character recognition failed to process the document."
        }
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
