//
//  ImageAttachment.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ImageAttachment: Identifiable, ObservableObject {
    var id: UUID = UUID()
    var url: URL?
    @Published var image: Image?
    @Published var thumbnail: Image?
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private(set) var originalFileType: UTType
    private var imageData: Data?

    init(url: URL) {
        self.url = url
        self.originalFileType = url.getUTType() ?? .jpeg
        self.loadImage()
    }

    init(image: Image, id: UUID = UUID()) {
        self.id = id
        self.image = image
        self.originalFileType = .jpeg
    }

    private func loadImage() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let url = self.url else { return }

            // For cross-platform compatibility, we'll use SwiftUI's Image with data loading
            do {
                let data = try Data(contentsOf: url)
                self.imageData = data // Store the data for base64 conversion
#if os(macOS)
                if let nsImage = NSImage(data: data) {
                    let swiftUIImage = Image(nsImage: nsImage)
                    DispatchQueue.main.async {
                        self.image = swiftUIImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = NSError(domain: "ImageAttachment", code: 1,
                                           userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                        self.isLoading = false
                    }
                }
#else
                if let uiImage = UIImage(data: data) {
                    let swiftUIImage = Image(uiImage: uiImage)
                    DispatchQueue.main.async {
                        self.image = swiftUIImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = NSError(domain: "ImageAttachment", code: 1,
                                           userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                        self.isLoading = false
                    }
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

    // Convert image to base64 string for API requests
    func toBase64() -> String? {
        // If we have stored image data, use it
        if let imageData = self.imageData {
            return imageData.base64EncodedString()
        }

        // Fallback: try to get data from URL if available
        guard let url = self.url else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return data.base64EncodedString()
        } catch {
            print("Failed to convert image to base64: \(error)")
            return nil
        }
    }
}

