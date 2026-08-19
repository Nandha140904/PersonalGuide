// MARK: - DocumentScannerView.swift
// PersonalGuide
//
// SwiftUI wrapper for Apple's native VisionKit VNDocumentCameraViewController.
// Features automatic edge detection, perspective correction, flash control, and multi-page scanning.

import SwiftUI
import VisionKit

public struct DocumentScannerView: UIViewControllerRepresentable {

    public typealias UIViewControllerType = VNDocumentCameraViewController

    private let onScanned: ([UIImage]) -> Void
    private let onCancelled: () -> Void
    private let onError: (Error) -> Void

    public init(
        onScanned: @escaping ([UIImage]) -> Void,
        onCancelled: @escaping () -> Void,
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        self.onScanned = onScanned
        self.onCancelled = onCancelled
        self.onError = onError
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    // MARK: - Coordinator

    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        public init(parent: DocumentScannerView) {
            self.parent = parent
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: pageIndex))
            }
            parent.onScanned(scannedImages)
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancelled()
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onError(error)
            parent.onCancelled()
        }
    }
}
