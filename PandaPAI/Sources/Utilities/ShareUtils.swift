//
//  ShareUtils.swift
//  macai
//
//  Created by Kilo Code on 05.09.2025.
//

import Foundation
import SwiftUI

struct ShareUtils {
    /// Formats a single message for sharing
    static func formatMessageForSharing(_ message: MessageEntity) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        let role = message.own ? "You" : (message.chat?.persona?.name ?? "Assistant")
        let timestamp = dateFormatter.string(from: message.timestamp)

        return """
        [\(role) - \(timestamp)]
        \(message.body)

        """
    }

    /// Formats an entire chat conversation for sharing
    static func formatChatForSharing(_ chat: ChatEntity) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var result = "Chat: \(chat.name.isEmpty ? "Untitled" : chat.name)\n"
        result += "Created: \(dateFormatter.string(from: chat.createdDate))\n"
        result += "Persona: \(chat.persona?.name ?? "Default")\n\n"

        if !chat.systemMessage.isEmpty {
            result += "[System Message]\n\(chat.systemMessage)\n\n"
        }

        for message in chat.messagesArray {
            result += formatMessageForSharing(message)
        }

        result += "\n--- Shared from macai ---"

        return result
    }

    /// Creates a temporary file with chat data for sharing
    static func createChatFileForSharing(_ chat: ChatEntity) throws -> URL {
        let chatData = formatChatForSharing(chat)
        let fileName = "chat_\(chat.name.isEmpty ? "untitled" : chat.name.replacingOccurrences(of: " ", with: "_"))_\(getCurrentFormattedDate()).txt"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try chatData.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    /// Creates a JSON file for sharing (similar to export)
    static func createChatJSONForSharing(_ chat: ChatEntity) throws -> URL {
        let legacyChat = Chat(chatEntity: chat)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(legacyChat)
        let fileName = "chat_\(chat.name.isEmpty ? "untitled" : chat.name.replacingOccurrences(of: " ", with: "_"))_\(getCurrentFormattedDate()).json"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        return fileURL
    }

    /// Helper function to get current date formatted for filenames
    private static func getCurrentFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}