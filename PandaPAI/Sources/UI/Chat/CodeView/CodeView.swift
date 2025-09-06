//
//  CodeView.swift
//  macai
//
//  Created by Renat on 07.06.2024.
//

import Foundation
import Highlightr
import SwiftUI

struct CodeView: View {
    let code: String
    let lang: String
    var isStreaming: Bool
    var message: MessageEntity?
    @Binding var searchText: String
    var currentSearchOccurrence: SearchOccurrence?
    @StateObject private var viewModel: CodeViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var previewStateManager: PreviewStateManager
    @State private var highlightedCode: AttributedString?
    @State private var isRendered = false
    @AppStorage("chatFontSize") private var chatFontSize: Double = 14.0
    @AppStorage("codeFont") private var codeFont: String = AppConstants.firaCode
    
    let elementIndex: Int
    
    init(code: String, lang: String, isStreaming: Bool = false, message: MessageEntity?, searchText: Binding<String>, currentSearchOccurrence: SearchOccurrence?, elementIndex: Int) {
        self.code = code
        self.lang = lang
        self.isStreaming = isStreaming
        self.message = message
        self._searchText = searchText
        self.currentSearchOccurrence = currentSearchOccurrence
        self.elementIndex = elementIndex
        _viewModel = StateObject(
            wrappedValue: CodeViewModel(
                code: code,
                language: lang,
                isStreaming: isStreaming
            )
        )
    }
    
    var body: some View {
        VStack {
            headerView
            if let highlighted = highlightedCode {

                let finalAttributedString = searchText == "" ? highlighted : applySearchHighlighting(to: highlighted)
                Text(finalAttributedString)
                    .textSelection(.enabled)
                    .padding([.horizontal, .bottom], 12)
            }
            else {
                Text(code)
                    .textSelection(.enabled)
                    .padding([.horizontal, .bottom], 12)
                    .font(.custom(codeFont, size: chatFontSize - 1))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .onChange(of: colorScheme) { _,newScheme in
            updateHighlightedCode(colorScheme: newScheme)
        }
        .onChange(of: code) { _,code in
            if isStreaming {
                print("Code changed: \(code)")
                updateHighlightedCode(colorScheme: colorScheme, code: code)
            }
        }
        .onChange(of: highlightedCode) { _,_ in
            if !isRendered {
                isRendered = true
                NotificationCenter.default.post(
                    name: NSNotification.Name("CodeBlockRendered"),
                    object: nil
                )
            }
        }
        .onAppear {
            updateHighlightedCode(colorScheme: colorScheme)
        }
        .onChange(of: chatFontSize) { _,_ in
            HighlighterManager.shared.invalidateCache()
            updateHighlightedCode(colorScheme: colorScheme)
        }
        .onChange(of: codeFont) { _,_ in
            HighlighterManager.shared.invalidateCache()
            updateHighlightedCode(colorScheme: colorScheme)
        }
    }

    private var headerView: some View {
        HStack {
            if lang != "" {
                Text(lang)
                    .fontWeight(.bold)
            }
            Spacer()

            HStack(spacing: 12) {
                if lang.lowercased() == "html" {
                    runButton
                }
                copyButton
            }
        }
        .padding(12)

    }

    private var copyButton: some View {
        Button(action: viewModel.copyToClipboard) {
            Image(systemName: viewModel.isCopied ? "checkmark" : "doc.on.doc")
                .frame(height: 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var runButton: some View {
        Button(action: togglePreview) {
            Image(systemName: previewStateManager.isPreviewVisible ? "play.slash" : "play")
                .frame(height: 12)

            Text("Run")
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func togglePreview() {
        if previewStateManager.isPreviewVisible {
            previewStateManager.hidePreview()
        }
        else {
            previewStateManager.showPreview(content: code)
        }
    }

    private var codeBackground: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.96, green: 0.96, blue: 0.96)
    }

    private func updateHighlightedCode(colorScheme: ColorScheme, code: String = "") {
        DispatchQueue.main.async {
            if code != "" {
                viewModel.code = code
            }
            viewModel.updateHighlighting(colorScheme: colorScheme)
            if let nsHighlighted = viewModel.highlightedCode,
               let attributedString = try? AttributedString(nsHighlighted) {
                highlightedCode = attributedString
            } else {
                highlightedCode = nil
            }
        }
    }
    
    private func applySearchHighlighting(to attributedString: AttributedString) -> AttributedString {
        guard !searchText.isEmpty, let messageId = message?.objectID else { return attributedString }

        var mutableAttributedString = attributedString
        let body = String(attributedString.characters)
        var searchStartIndex = body.startIndex

        while let range = body.range(of: searchText, options: .caseInsensitive, range: searchStartIndex..<body.endIndex) {
            let occurrence = SearchOccurrence(
                messageID: messageId,
                range: NSRange(range, in: body),
                elementIndex: elementIndex,
                elementType: "code"
            )
            let isCurrent = occurrence == self.currentSearchOccurrence
            let color = isCurrent
                ? Color(Color(hex: AppConstants.currentHighlightColor) ?? Color.yellow)
                : Color(Color(hex: AppConstants.defaultHighlightColor) ?? Color.gray).withAlphaComponent(0.3)

            if let attributedRange = Range(range, in: attributedString) {
                mutableAttributedString[attributedRange].backgroundColor = color
            }
            searchStartIndex = range.upperBound
        }

        return mutableAttributedString
    }
}

#Preview {
    CodeView(code: "<h1>Hello World</h1>", lang: "html", message: nil, searchText: .constant(""), currentSearchOccurrence: nil, elementIndex: 0)
        .environmentObject(PreviewStateManager())
}
