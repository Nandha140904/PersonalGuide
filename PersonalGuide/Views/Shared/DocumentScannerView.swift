// MARK: - DocumentScannerView.swift
// PersonalGuide
//
// SwiftUI wrapper for Apple's native VisionKit VNDocumentCameraViewController.
// Features automatic edge detection, perspective correction, flash control, and multi-page scanning.

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {

    typealias UIViewControllerType = VNDocumentCameraViewController

    @MainActor private let onScanned: @MainActor ([UIImage]) -> Void
    @MainActor private let onCancelled: @MainActor () -> Void
    @MainActor private let onError: @MainActor (Error) -> Void

    init(
        onScanned: @escaping @MainActor ([UIImage]) -> Void,
        onCancelled: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (Error) -> Void = { _ in }
    ) {
        self.onScanned = onScanned
        self.onCancelled = onCancelled
        self.onError = onError
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: pageIndex))
            }
            parent.onScanned(scannedImages)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancelled()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onError(error)
            parent.onCancelled()
        }
    }
}
