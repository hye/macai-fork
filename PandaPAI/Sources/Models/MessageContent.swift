//
//  MessageContent.swift
//  macai
//
//  Created by Renat on 03.04.2025
//

import CoreData
import Foundation
import SwiftUI

struct MessageContent {
    let content: String
    var fileAttachment: FileAttachment?

    init(text: String) {
        self.content = text
        self.fileAttachment = nil
    }

    init(fileUUID: UUID) {
        self.content = "<file-uuid>\(fileUUID.uuidString)</file-uuid>"
        self.fileAttachment = nil
    }

    init(fileAttachment: FileAttachment) {
        self.content = "<file-uuid>\(fileAttachment.id.uuidString)</file-uuid>"
        self.fileAttachment = fileAttachment
    }
}

/// Extension to convert between MessageContent array and string representation
extension Array where Element == MessageContent {
    func toString() -> String {
        map { $0.content }.joined(separator: "\n")
    }

    var textContent: String {
        map {
            $0.content.replacingOccurrences(of: "<file-uuid>.*?</file-uuid>", with: "", options: .regularExpression)
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fileUUIDs: [UUID] {
        compactMap { content in
            let pattern = "<file-uuid>(.*?)</file-uuid>"
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsString = content.content as NSString
            let matches =
                regex?.matches(in: content.content, options: [], range: NSRange(location: 0, length: nsString.length))
                ?? []

            if let match = matches.first, match.numberOfRanges > 1 {
                let uuidRange = match.range(at: 1)
                let uuidString = nsString.substring(with: uuidRange)
                return UUID(uuidString: uuidString)
            }
            return nil
        }
    }
}
extension String {
    func toMessageContents() -> [MessageContent] {
        [MessageContent(text: self)]
    }

    func extractFileUUIDs() -> [UUID] {
        let pattern = "<file-uuid>(.*?)</file-uuid>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = self as NSString
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []

        return matches.compactMap { match in
            if match.numberOfRanges > 1 {
                let uuidRange = match.range(at: 1)
                let uuidString = nsString.substring(with: uuidRange)
                return UUID(uuidString: uuidString)
            }
            return nil
        }
    }
}
