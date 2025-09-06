import CoreData
//
//  MessageParser.swift
//  macai
//
//  Created by Renat Notfullin on 25.04.2023.
//
import Foundation
import Highlightr
import SwiftUI

struct MessageParser {
    @State var colorScheme: ColorScheme

    enum BlockType {
        case text
        case table
        case codeBlock
        case formulaBlock
        case formulaLine
        case thinking
        case imageUUID
    }

    func detectBlockType(line: String) -> BlockType {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        if trimmedLine.hasPrefix("<think>") {
            return .thinking
        }
        else if trimmedLine.hasPrefix("```") {
            return .codeBlock
        }
        else if trimmedLine.first == "|" {
            return .table
        }
        else if trimmedLine.hasPrefix("\\[") {
            return trimmedLine.replacingOccurrences(of: " ", with: "") == "\\[" ? .formulaBlock : .formulaLine
        }
        else if trimmedLine.hasPrefix("\\]") {
            return .formulaLine
        }
        else if trimmedLine.hasPrefix("<image-uuid>") {
            return .imageUUID
        }
        else {
            return .text
        }
    }

    func parseMessageFromString(input: String) -> [MessageElements] {

        let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var elements: [MessageElements] = []
        var currentHeader: [String] = []
        var currentTableData: [[String]] = []
        var textLines: [String] = []
        var codeLines: [String] = []
        var formulaLines: [String] = []
        var firstTableRowProcessed = false
        var isCodeBlockOpened = false
        var isFormulaBlockOpened = false
        var codeBlockLanguage = ""
        var leadingSpaces = 0

        func toggleCodeBlock(line: String) {
            if isCodeBlockOpened {
                appendCodeBlockIfNeeded()
                isCodeBlockOpened = false
                codeBlockLanguage = ""
                leadingSpaces = 0
            }
            else {
                // extract codeBlockLanguage and remove leading spaces
                codeBlockLanguage = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "```", with: "")
                isCodeBlockOpened = true
            }
        }

        func openFormulaBlock() {
            isFormulaBlockOpened = true
        }

        func closeFormulaBlock() {
            isFormulaBlockOpened = false
        }

        func handleFormulaLine(line: String) {
            let formulaString = line.replacingOccurrences(of: "\\[", with: "").replacingOccurrences(of: "\\]", with: "")
            formulaLines.append(formulaString)
        }

        func appendFormulaLines() {
            let combinedLines = formulaLines.joined(separator: "\n")
            elements.append(.formula(combinedLines))
        }

        func handleTableLine(line: String) {

            combineTextLinesIfNeeded()

            let rowData = parseRowData(line: line)

            if rowDataIsTableDelimiter(rowData: rowData) {
                return
            }

            if !firstTableRowProcessed {
                handleFirstRowData(rowData: rowData)
            }
            else {
                handleSubsequentRowData(rowData: rowData)
            }
        }

        func rowDataIsTableDelimiter(rowData: [String]) -> Bool {
            return rowData.allSatisfy({ $0.allSatisfy({ $0 == "-" || $0 == ":" }) })
        }

        func parseRowData(line: String) -> [String] {
            return line.split(separator: "|")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        func handleFirstRowData(rowData: [String]) {
            currentHeader = rowData
            firstTableRowProcessed = true
        }

        func handleSubsequentRowData(rowData: [String]) {
            currentTableData.append(rowData)
        }

        func combineTextLinesIfNeeded() {
            if !textLines.isEmpty {
                let combinedText = textLines.reduce("") { (result, line) -> String in
                    if result.isEmpty {
                        return line
                    }
                    else {
                        return result + "\n" + line
                    }
                }
                elements.append(.text(combinedText))
                textLines = []
            }
        }

        func appendTableIfNeeded() {
            if !currentTableData.isEmpty {
                appendTable()
            }
        }

        func appendTable() {
            elements.append(.table(header: currentHeader, data: currentTableData))
            currentHeader = []
            currentTableData = []
            firstTableRowProcessed = false
        }

        func appendCodeBlockIfNeeded() {
            if !codeLines.isEmpty {
                let combinedCode = codeLines.joined(separator: "\n")
                elements.append(.code(code: combinedCode, lang: codeBlockLanguage, indent: leadingSpaces))
                codeLines = []
            }
        }

        func extractImageUUID(_ line: String) -> UUID? {
            let pattern = "<image-uuid>(.*?)</image-uuid>"
            if let range = line.range(of: pattern, options: .regularExpression) {
                let uuidString = String(line[range])
                    .replacingOccurrences(of: "<image-uuid>", with: "")
                    .replacingOccurrences(of: "</image-uuid>", with: "")
                return UUID(uuidString: uuidString)
            }
            return nil
        }

        func loadImageFromCoreData(uuid: UUID) -> Image? {
            let viewContext = PersistenceController.shared.container.viewContext

            let fetchRequest: NSFetchRequest<ImageEntity> = ImageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                let results = try viewContext.fetch(fetchRequest)
                if let imageEntity = results.first, let imageData = imageEntity.image {
                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        return Image(nsImage: nsImage)
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        return Image(uiImage: uiImage)
                    }
                    #endif
                }
            }
            catch {
                print("Error fetching image from CoreData: \(error)")
            }

            return nil
        }

        var thinkingLines: [String] = []
        var isThinkingBlockOpened = false

        func appendThinkingBlockIfNeeded() {
            if !thinkingLines.isEmpty {
                let combinedThinking = thinkingLines.joined(separator: "\n")
                    .replacingOccurrences(of: "<think>", with: "")
                    .replacingOccurrences(of: "</think>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                elements.append(.thinking(combinedThinking, isExpanded: false))
                thinkingLines = []
            }
        }

        func finalizeParsing() {
            combineTextLinesIfNeeded()
            appendCodeBlockIfNeeded()
            appendTableIfNeeded()
            appendThinkingBlockIfNeeded()
        }

        for line in lines {
            let blockType = detectBlockType(line: line)

            switch blockType {

            case .codeBlock:
                leadingSpaces = line.count - line.trimmingCharacters(in: .whitespaces).count
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                toggleCodeBlock(line: line)

            case .table:
                handleTableLine(line: line)

            case .formulaBlock:
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                openFormulaBlock()

            case .formulaLine:
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("\\]") {
                    closeFormulaBlock()
                    appendFormulaLines()
                }
                else {
                    handleFormulaLine(line: line)
                    if !isFormulaBlockOpened {
                        appendFormulaLines()
                    }
                }

            case .thinking:
                if line.contains("</think>") {
                    let thinking =
                        line
                        .replacingOccurrences(of: "<think>", with: "")
                        .replacingOccurrences(of: "</think>", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    elements.append(.thinking(thinking, isExpanded: false))
                }
                else if line.contains("<think>") {
                    combineTextLinesIfNeeded()
                    appendTableIfNeeded()
                    isThinkingBlockOpened = true

                    let firstLine = line.replacingOccurrences(of: "<think>", with: "")
                    if !firstLine.isEmpty {
                        thinkingLines.append(firstLine)
                    }
                }

            case .imageUUID:
                if let uuid = extractImageUUID(line), let image = loadImageFromCoreData(uuid: uuid) {
                    combineTextLinesIfNeeded()
                    elements.append(.image(image))
                }
                else {
                    textLines.append(line)
                }

            case .text:
                if isThinkingBlockOpened {
                    if line.contains("</think>") {
                        let lastLine = line.replacingOccurrences(of: "</think>", with: "")
                        if !lastLine.isEmpty {
                            thinkingLines.append(lastLine)
                        }
                        isThinkingBlockOpened = false
                        appendThinkingBlockIfNeeded()
                    }
                    else {
                        thinkingLines.append(line)
                    }
                }
                else if isCodeBlockOpened {
                    if leadingSpaces > 0 {
                        codeLines.append(String(line.dropFirst(leadingSpaces)))
                    }
                    else {
                        codeLines.append(line)
                    }
                }
                else if isFormulaBlockOpened {
                    handleFormulaLine(line: line)
                }
                else {
                    if !currentTableData.isEmpty {
                        appendTable()
                    }
                    textLines.append(line)
                }
            }
        }

        finalizeParsing()
        return elements
    }
}
