// MARK: - DocumentScannerView.swift
// PersonalGuide
//
// SwiftUI wrapper for Apple's native VisionKit VNDocumentCameraViewController.
// Features automatic edge detection, perspective correction, flash control, and multi-page scanning.

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {

    typealias UIViewControllerType = VNDocumentCameraViewController

    private let onScanned: ([UIImage]) -> Void
    private let onCancelled: () -> Void
    private let onError: (Error) -> Void

    init(
        onScanned: @escaping ([UIImage]) -> Void,
        onCancelled: @escaping () -> Void,
        onError: @escaping (Error) -> Void = { _ in }
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
