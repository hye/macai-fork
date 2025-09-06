//
//  FileAttachment.swift
//  macai
//
//  Created by AI Assistant on 05.09.2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class FileAttachment: Identifiable, ObservableObject {
    var id: UUID = UUID()
    var url: URL?
    var fileName: String
    var fileSize: Int64?
    var fileType: UTType?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // For image files
    @Published var image: Image?
    @Published var thumbnail: Image?

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.fileType = url.getUTType()

        // Ensure we have access to security-scoped URL
        let hasAccess = url.startAccessingSecurityScopedResource()
        if !hasAccess {
            print("Warning: Could not access security-scoped resource for \(url)")
        }

        self.loadFileInfo()

        // Stop accessing after loading is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private func loadFileInfo() {
        guard let url = self.url else { return }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int64

            // If it's an image, load the image
            if let fileType = self.fileType, fileType.conforms(to: .image) {
                loadImage()
            }
        } catch {
            self.error = error
        }
    }

    private func loadImage() {
        guard let url = self.url else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try Data(contentsOf: url)
                #if os(iOS)
                if let uiImage = UIImage(data: data) {
                    let swiftUIImage = Image(uiImage: uiImage)
                    DispatchQueue.main.async {
                        self.image = swiftUIImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = NSError(domain: "FileAttachment", code: 1,
                                           userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                        self.isLoading = false
                    }
                }
                #else
                // For macOS, similar logic
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                #endif
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    // Get file data for upload
    func getFileData() -> Data? {
        guard let url = self.url else { return nil }
        return try? Data(contentsOf: url)
    }

    // Check if file is an image
    var isImage: Bool {
        guard let fileType = self.fileType else { return false }
        return fileType.conforms(to: .image)
    }

    // Get display icon based on file type
    var displayIcon: String {
        guard let fileType = self.fileType else { return "doc" }

        if fileType.conforms(to: .image) {
            return "photo"
        } else if fileType.conforms(to: .pdf) {
            return "doc.richtext"
        } else if fileType.conforms(to: .text) {
            return "doc.text"
        } else if fileType.conforms(to: .json) {
            return "doc.plaintext"
        } else {
            return "doc"
        }
    }

    // Get formatted file size
    var formattedFileSize: String {
        guard let fileSize = self.fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

extension URL {
    func getUTType() -> UTType? {
        let fileExtension = self.pathExtension.lowercased()

        switch fileExtension {
        case "jpg", "jpeg":
            return .jpeg
        case "png":
            return .png
        case "webp":
            return .webP
        case "heic":
            return .heic
        case "heif":
            return .heif
        case "pdf":
            return .pdf
        case "txt":
            return .text
        case "json":
            return .json
        default:
            return UTType(filenameExtension: fileExtension)
        }
    }
}