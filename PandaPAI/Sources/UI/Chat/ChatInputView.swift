//
//  ChatInputView.swift
//  macai
//
//  Created by AI Assistant on 20.01.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ChatInputView: View {
    @ObservedObject var chat: ChatEntity
    @Binding var newMessage: String
    @Binding var editSystemMessage: Bool
    @Binding var attachedFiles: [FileAttachment]
    @Binding var isBottomContainerExpanded: Bool

    let fileUploadsAllowed: Bool
    let onSendMessage: () -> Void
    let onAddFile: () -> Void
    
    @StateObject private var store = ChatStore(persistenceController: PersistenceController.shared)
    @State private var showDocumentPicker = false
    @State private var selectedDocumentURLs: [URL] = []
    
    var body: some View {
        ChatBottomContainerView(
            chat: chat,
            newMessage: $newMessage,
            isExpanded: $isBottomContainerExpanded,
            attachedFiles: $attachedFiles,
            fileUploadsAllowed: fileUploadsAllowed,
            onSendMessage: {
                if editSystemMessage {
                    chat.systemMessage = newMessage
                    newMessage = ""
                    editSystemMessage = false
                    store.saveInCoreData()
                }
                else if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSendMessage()
                }
            },
            onAddFile: {
                #if os(iOS)
                showDocumentPicker = true
                #else
                onAddFile()
                #endif
            }
        )
#if os(iOS)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(
                selectedURLs: $selectedDocumentURLs,
                allowedContentTypes: [.image, .pdf, .text, .json],
                allowsMultipleSelection: true,
                onDocumentPicked: { urls in
                    let newAttachments = urls.map { FileAttachment(url: $0) }
                    withAnimation {
                        attachedFiles.append(contentsOf: newAttachments)
                    }
                    showDocumentPicker = false
                },
                onCancel: {
                    showDocumentPicker = false
                }
            )
        }
#endif
    }
}

#Preview {
    ChatInputView(
        chat: ChatEntity(),
        newMessage: .constant("Test message"),
        editSystemMessage: .constant(false),
        attachedFiles: .constant([]),
        isBottomContainerExpanded: .constant(false),
        fileUploadsAllowed: true,
        onSendMessage: {},
        onAddFile: {}
    )
}
