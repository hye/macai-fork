//
//  ChatBottomContainerView.swift
//  macai
//
//  Created by Renat on 19.01.2025.
//
import SwiftUI

struct ChatBottomContainerView: View {
    @ObservedObject var chat: ChatEntity
    @Binding var newMessage: String
    @Binding var isExpanded: Bool
    @Binding var attachedFiles: [FileAttachment]
    var fileUploadsAllowed: Bool
    var onSendMessage: () -> Void
    var onExpandToggle: () -> Void
    var onAddFile: () -> Void
    var onExpandedStateChange: ((Bool) -> Void)?  // Add this line

    init(
        chat: ChatEntity,
        newMessage: Binding<String>,
        isExpanded: Binding<Bool>,
        attachedFiles: Binding<[FileAttachment]> = .constant([]),
        fileUploadsAllowed: Bool = false,
        onSendMessage: @escaping () -> Void,
        onExpandToggle: @escaping () -> Void = {},
        onAddFile: @escaping () -> Void = {},
        onExpandedStateChange: ((Bool) -> Void)? = nil
    ) {
        self.chat = chat
        self._newMessage = newMessage
        self._isExpanded = isExpanded
        self._attachedFiles = attachedFiles
        self.fileUploadsAllowed = fileUploadsAllowed
        self.onSendMessage = onSendMessage
        self.onExpandToggle = onExpandToggle
        self.onAddFile = onAddFile
        self.onExpandedStateChange = onExpandedStateChange

        if chat.messages.count == 0 {
            DispatchQueue.main.async {
                isExpanded.wrappedValue = true
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                        onExpandedStateChange?(isExpanded)
                    }
                }) {
                    HStack {
                        Text(chat.persona?.name ?? "Select Assistant")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, -16)
            }

            VStack(spacing: 0) {
                VStack {
                    if isExpanded {
                        PersonaSelectorView(chat: chat)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                HStack {
                    MessageInputView(
                        text: $newMessage,
                        attachedFiles: $attachedFiles,
                        fileUploadsAllowed: fileUploadsAllowed,
                        onEnter: onSendMessage,
                        onAddFile: onAddFile
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding()
                }
                .border(width: 1, edges: [.top], color: Color.primary.opacity(0.1))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                  UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }

    }
}
