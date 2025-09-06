//
//  DocumentPickerView.swift
//  macai
//
//  Created by AI Assistant on 05.09.2025.
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedURLs: [URL]
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onDocumentPicked: (([URL]) -> Void)?
    let onCancel: (() -> Void)?

    init(
        selectedURLs: Binding<[URL]>,
        allowedContentTypes: [UTType] = [],
        allowsMultipleSelection: Bool = false,
        onDocumentPicked: (([URL]) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self._selectedURLs = selectedURLs
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentPicked = onDocumentPicked
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker: UIDocumentPickerViewController

        if allowedContentTypes.isEmpty {
            // Allow all document types
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        } else {
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        }

        documentPicker.allowsMultipleSelection = allowsMultipleSelection
        documentPicker.delegate = context.coordinator
        documentPicker.shouldShowFileExtensions = true

        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Start accessing security-scoped resources
            var accessibleURLs: [URL] = []

            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    accessibleURLs.append(url)
                } else {
                    print("Failed to access security-scoped resource: \(url)")
                }
            }

            // Update the binding
            DispatchQueue.main.async {
                self.parent.selectedURLs = accessibleURLs
                self.parent.onDocumentPicked?(accessibleURLs)
            }

            // Keep access open for longer to allow file processing
            // The FileAttachment will handle stopping access when done
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                for url in accessibleURLs {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async {
                self.parent.onCancel?()
            }
        }
    }
}
#endif
