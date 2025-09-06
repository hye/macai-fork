//
//  MessageContentView.swift
//  macai
//
//  Created by Renat on 03.04.2025.
//

import Foundation
import SwiftUI

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: Image
}
struct MessageContentView: View {
    var message: MessageEntity?
    let content: String
    let isStreaming: Bool
    let own: Bool
    let effectiveFontSize: Double
    let colorScheme: ColorScheme
    @Binding var searchText: String
    var currentSearchOccurrence: SearchOccurrence?

    @State private var showFullMessage = false
    @State private var isParsingFullMessage = false
    @State private var selectedImage: IdentifiableImage?

    private let largeMessageSymbolsThreshold = AppConstants.largeMessageSymbolsThreshold

    var body: some View {
        VStack(alignment: .leading) {
            // Check if message contains image data or JSON with image_url before applying truncation
            if content.count > largeMessageSymbolsThreshold && !showFullMessage && !containsImageData(content) {
                renderPartialContent()
            }
            else {
                renderFullContent()
            }
        }
    }

    private func containsImageData(_ message: String) -> Bool {
        if message.contains("<image-uuid>") {
            return true
        }
        return false
    }

    @ViewBuilder
    private func renderPartialContent() -> some View {
        let truncatedMessage = String(content.prefix(largeMessageSymbolsThreshold))
        let parser = MessageParser(colorScheme: colorScheme)
        let parsedElements = parser.parseMessageFromString(input: truncatedMessage)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(parsedElements.indices, id: \.self) {
                index in
                renderElement(parsedElements[index], elementIndex: index)
            }

            HStack(spacing: 8) {
                Button(action: {
                    isParsingFullMessage = true
                    // Parse the full message in background: very long messages may take long time to parse (and even cause app crash)
                    DispatchQueue.global(qos: .userInitiated).async {
                        let parser = MessageParser(colorScheme: colorScheme)
                        _ = parser.parseMessageFromString(input: content)

                        DispatchQueue.main.async {
                            showFullMessage = true
                            isParsingFullMessage = false
                        }
                    }
                }) {
                    Text("Show Full Message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())

                if isParsingFullMessage {
                    ProgressView()
                        .scaleEffect(0.4)
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func renderFullContent() -> some View {
        let parser = MessageParser(colorScheme: colorScheme)
        let parsedElements = parser.parseMessageFromString(input: content)

        ForEach(parsedElements.indices, id: \.self) {
            index in
            renderElement(parsedElements[index], elementIndex: index)
                .id(generateElementID(elementIndex: index))
        }
    }
    
    private func generateElementID(elementIndex: Int) -> String {
        guard let messageID = message?.objectID else {
            return "element_\(elementIndex)"
        }
        let messageIDString = messageID.uriRepresentation().absoluteString
        return "\(messageIDString)_element_\(elementIndex)"
    }

    @ViewBuilder
    private func renderElement(_ element: MessageElements, elementIndex: Int) -> some View {
        switch element {
        case .thinking(let content, _):
            ThinkingProcessView(content: content)
                .padding(.vertical, 4)

        case .text(let text):
            renderText(text, elementIndex: elementIndex)

        case .table(let header, let data):
            TableView(header: header, tableData: data, searchText: $searchText, message: message, currentSearchOccurrence: currentSearchOccurrence, elementIndex: elementIndex)
                .padding()

        case .code(let code, let lang, let indent):
            renderCode(code: code, lang: lang, indent: indent, isStreaming: isStreaming, elementIndex: elementIndex)

        case .formula(let formula):
            if isStreaming {
                Text(formula).textSelection(.enabled)
            }
            else {
                AdaptiveMathView(equation: formula, fontSize: 16)
                    .padding(.vertical, 16)
            }

        case .image(let image):
            renderImage(image)
        }
    }

    @ViewBuilder
    private func renderText(_ text: String, elementIndex: Int = 0) -> some View {
        let attributedString: AttributedString = {
            var attributedString = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)

            // Apply base font and color
            attributedString.font = .system(size: effectiveFontSize)
            attributedString.foregroundColor = own ? .primary : .primary

            // Handle headers
            let stringValue = String(attributedString.characters)
            guard let headerRegex = try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.*)", options: .anchorsMatchLines) else { return attributedString }
            let headerMatches = headerRegex.matches(in: stringValue, options: [], range: NSRange(location: 0, length: stringValue.utf16.count))

            for match in headerMatches.reversed() {
                let fullMatchRange = match.range(at: 0)
                let prefixHashesRange = match.range(at: 1)
                let contentTextRange = match.range(at: 2)

                let level = prefixHashesRange.length
                let fontSize = max(effectiveFontSize + 10 - pow(CGFloat(level), 1.5), 6)

                if let contentRange = Range(contentTextRange, in: stringValue),
                   let attributedRange = Range(contentRange, in: attributedString) {
                    attributedString[attributedRange].font = .system(size: fontSize, weight: .bold)
                }

                // Remove the header prefix
                if let fullRange = Range(fullMatchRange, in: stringValue),
                   let contentRange = Range(contentTextRange, in: stringValue),
                   let attributedFullRange = Range(fullRange, in: attributedString),
                   let attributedContentRange = Range(contentRange, in: attributedString) {
                    attributedString.characters.removeSubrange(attributedFullRange.lowerBound..<attributedContentRange.lowerBound)
                }
            }

            // Handle quote blocks
            guard let quoteRegex = try? NSRegularExpression(pattern: "^\\s*>\\s*(.*)", options: .anchorsMatchLines) else { return attributedString }
            let quoteMatches = quoteRegex.matches(in: stringValue, options: [], range: NSRange(location: 0, length: stringValue.utf16.count))

            for match in quoteMatches.reversed() {
                let fullMatchRange = match.range(at: 0)
                let contentTextRange = match.range(at: 1)

                if let contentRange = Range(contentTextRange, in: stringValue),
                   let attributedRange = Range(contentRange, in: attributedString) {
                    attributedString[attributedRange].font = .system(size: effectiveFontSize, weight: .regular, design: .default)
                    let quoteColor = colorScheme == .dark ? Color.secondary : Color.gray.opacity(0.6)
                    attributedString[attributedRange].foregroundColor = quoteColor
                }

                // Remove the quote prefix
                if let fullRange = Range(fullMatchRange, in: stringValue),
                   let contentRange = Range(contentTextRange, in: stringValue),
                   let attributedFullRange = Range(fullRange, in: attributedString),
                   let attributedContentRange = Range(contentRange, in: attributedString) {
                    attributedString.characters.removeSubrange(attributedFullRange.lowerBound..<attributedContentRange.lowerBound)
                }
            }

            // Apply search highlighting if searchText is not empty
            if !searchText.isEmpty, let messageId = message?.objectID {
                let body = String(attributedString.characters)
                let originalBody = text
                var searchStartIndex = body.startIndex
                var originalSearchStartIndex = originalBody.startIndex

                while let range = body.range(of: searchText, options: .caseInsensitive, range: searchStartIndex..<body.endIndex),
                      let originalRange = originalBody.range(of: searchText, options: .caseInsensitive, range: originalSearchStartIndex..<originalBody.endIndex) {
                    let occurrence = SearchOccurrence(messageID: messageId, range: NSRange(originalRange, in: originalBody), elementIndex: elementIndex, elementType: "text")
                    let isCurrent = occurrence == self.currentSearchOccurrence
                    let color = isCurrent
                         ? Color(hex: AppConstants.currentHighlightColor) ?? Color.yellow
                         : (Color(hex: AppConstants.defaultHighlightColor) ?? Color.gray).opacity(0.3)

                    if let attributedRange = Range(range, in: attributedString) {
                        attributedString[attributedRange].backgroundColor = color
                    }
                    searchStartIndex = range.upperBound
                    originalSearchStartIndex = originalRange.upperBound
                }
            }

            return attributedString
        }()

        if text.count > AppConstants.longStringCount {
            Text(attributedString)
                .textSelection(.enabled)
        } else {
            Text(attributedString)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func renderCode(code: String, lang: String, indent: Int, isStreaming: Bool, elementIndex: Int) -> some View {
        CodeView(code: code, lang: lang, isStreaming: isStreaming, message: message, searchText: $searchText, currentSearchOccurrence: currentSearchOccurrence, elementIndex: elementIndex)
            .padding(.bottom, 8)
            .padding(.leading, CGFloat(indent) * 4)
            .onAppear {
                NotificationCenter.default.post(name: NSNotification.Name("CodeBlockRendered"), object: nil)
            }
    }

    @ViewBuilder
    private func renderImage(_ image: Image) -> some View {
        let maxWidth: CGFloat = 300

        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: maxWidth)
            .cornerRadius(8)
            .padding(.bottom, 3)
            .onTapGesture {
                selectedImage = IdentifiableImage(image: image)
            }
            .sheet(item: $selectedImage) { identifiableImage in
                ZoomableImageView(image: identifiableImage.image, imageAspectRatio: 1.0)
            }
    }

}

